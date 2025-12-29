#!/usr/bin/perl

# Creates an open positions CSV file from a
# Stone statement TXT file.
# 
# Version that handles ICE ENO Daily Options.
# 2025.12.29
# janeiros@mbfcc.com

use strict;
use warnings;

use v5.010;

use feature 'say';

my %multipliers = ();

# Use the GNU Multiple Precision Libary or the Pary library
# if they are available, if not fallback to pure Perl and
# don't break.
use Math::BigFloat try => 'GMP,Pari';

#say Math::BigFloat->config->{lib};

sub parse_number_fraction {

    my ($s, $mode, $tick_size) = @_;
    
    $mode ||= 'financial';
    
    $s =~ s/^\s+|\s+$//g;

    # Match "base n/d" with ASCII only
    if (my ($base_str, $n_str, $d_str) = $s =~ /
        ^
        (               # Start of base group capture.
        [+-]?\d*        # Integer portion. It could not be present, like .92
        (?:\.\d+)?      # Decimal part, optional, no group capture.
        )               # End of base group capture.
        \s+             # Spaces between base and fraction.
        ([+-]?\d+)      # Numerator portion capture.
        \s*\/\s*        # with optional spaces before and after.
        (\d+)           # Denominator portion capture.
        $/x)
    {
        
        my $base = Math::BigFloat->new($base_str);
        my $n    = Math::BigFloat->new($n_str);
        my $d    = Math::BigFloat->new($d_str);
        
        die "Denominator cannot be zero" if $d->is_zero();

        my $fraction = $n->copy()->bdiv($d);

        if ($mode eq 'literal') {
            return $base->copy()->badd($fraction);
    
        } elsif ($mode eq 'financial') {
    
            my $unit;
    
            if (defined $tick_size) {

                $unit = Math::BigFloat->new($tick_size);
                die "tick_size must be positive" if $unit <= 0;
            
            } else {
            
                # LSP from base
                my $scale = 0;
                $scale = length($1) if $base_str =~ /\.(\d+)/;
            
                $unit = Math::BigFloat->new(1);
                $unit->bdiv(Math::BigFloat->new(10)->bpow($scale));
            }
    
            return $base->copy()->badd($fraction->copy()->bmul($unit));
    
        } else {
            die "mode must be 'financial' or 'literal'";
        }
    
    } else {
        # Try plain number
        eval { return Math::BigFloat->new($s) } or die "Unrecognized format; expected 'base n/d' or plain number";
    }
}

sub clean_date {

	my ($date) = @_;

	my ($month, $day, $year) = (split /\//, $date);

	$year = '20'. $year;

	return "$month/$day/$year";
}

sub daily_contract_to_date {
	
	my ($contract) = @_;

	my ($contract_month, $year, $day) =
		$contract =~
			/
			([FGHJKMNQUVXZ])	# Month
			(\d{2})				# Year
			\.					# Daily deilimiter
			(\d+)				# Day
			/x;
	
	my $month = '';	
	if ($contract_month eq 'F') {
		$month = '1';
	} elsif ($contract_month eq 'G') {
		$month = '2';
	} elsif ($contract_month eq 'H') {
		$month = '3';
	} elsif ($contract_month eq 'J') {
		$month = '4';
	} elsif ($contract_month eq 'K') {
		$month = '5';
	} elsif ($contract_month eq 'M') {
		$month = '6';
	} elsif ($contract_month eq 'N') {
		$month = '7';
	} elsif ($contract_month eq 'Q') {
		$month = '8';
	} elsif ($contract_month eq 'U') {
		$month = '9';
	} elsif ($contract_month eq 'V') {
		$month = '10';
	} elsif ($contract_month eq 'X') {
		$month = '11';
	} elsif ($contract_month eq 'Z') {
		$month = '12';
	}

	$year = '20'. $year;
	
	return "$month/$day/$year";
}

# Create strike price multipliers.
sub create_multipliers {

        my %multipliers = ();

        while (<DATA>) {
            my ($symbol, $multiplier) = split /,/;
            $multipliers{$symbol} = $multiplier;
        }

        return %multipliers;
}

# Convert strike price to DB representation.
sub convert_strike {

        my ($symbol, $strike) = @_;

        if (defined($multipliers{$symbol})) {
            $strike = $strike * $multipliers{$symbol};
        }

        if ($strike =~ /^-/) {
            $strike *= -1;
            $strike = sprintf("-%05s", $strike);
        } else {
            $strike = sprintf("%05s", $strike);
        }

        return $strike;
}

sub process_option {

	my ($line) = @_;

	my $description = substr($line, 50, 30);
	my $putcall = substr($description, 0, 4);
	my $month = substr($description, 5, 3);
	my $year = substr($description, 9, 2);
	my $symbol = substr($description, 12, 13);
	my $strike = substr($description, 25, 5);

	# Clean the last portion of the symbol string
	$symbol =~ s/\s(SE|E|F|P|L|H|S|T|SG|G|D|GG)\s*$//;
	$symbol =~ s/\s+$//;
	$putcall =~ s/[\sUTALL]//g;

	# To have a different symbol for the options
	$symbol = sprintf("%s OPT", $symbol);

	# Convert to DB representation.
	my $contract = convert_contract($month . $year);
	
	$strike =~ s/\s//g;

	# Convert to DB representation.
	$strike = convert_strike($symbol, $strike);
	
	$contract = sprintf("%s%6s%s", $contract, $strike, $putcall);

	return ($symbol, $contract);
}

# Because of the REGEX it only handle ICE ENO options.
sub process_daily_option {

	my ($line) = @_;

	my ($put_call, $contract, $symbol, $strike) =
		/(C|P)\s+(\d{1,2}(?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\d{2})\s+(ICE\s+ENO)\s+(\d{1,})/;

	$contract = convert_daily_contract($contract);

	$strike =~ s/\s//g;

	# Convert to DB representation.
	$strike = convert_strike($symbol, $strike);

	$symbol =~ s/\s+/ /g;

	# To have a different symbol for the options
	$symbol = sprintf("%s OPT", $symbol);

	$contract = sprintf("%s %s%s", $contract, $strike, $put_call);

	return ($symbol, $contract);
}

sub convert_daily_contract() {

	my ($token) = @_;

	my ($day, $month, $year) =
		$token =~ /(\d{1,2})(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)(\d{2})/;

	my $db_month = convert_month($month);

	return sprintf("%s%s.%s", $db_month, $year, $day);
}

# Convert month to DB representation.
sub convert_month {

	my ($month) = @_;

	my $db_month = '';

	if ($month eq 'JAN') {
		$db_month = 'F';
	} elsif ($month eq 'FEB') {
		$db_month = 'G';
	} elsif ($month eq 'MAR') {
		$db_month = 'H';
	} elsif ($month eq 'APR') {
		$db_month = 'J';
	} elsif ($month eq 'MAY') {
		$db_month = 'K';
	} elsif ($month eq 'JUN') {
		$db_month = 'M';
	} elsif ($month eq 'JUL') {
		$db_month = 'N';
	} elsif ($month eq 'AUG') {
		$db_month = 'Q';
	} elsif ($month eq 'SEP') {
		$db_month = 'U';
	} elsif ($month eq 'OCT') {
		$db_month = 'V';
	} elsif ($month eq 'NOV') {
		$db_month = 'X';
	} elsif ($month eq 'DEC') {
		$db_month = 'Z';
	}

	return $db_month; 
}

# Convert contract to DB representation.
sub convert_contract {

	my ($contract, $days) = @_;

	my $month = substr($contract, 0, 3);
	my $year = substr($contract, 3, 2);

	my $db_month = convert_month($month);

	$db_month .= $year;
	
	if (defined($days)) {
		$db_month .= ".$days";
	}

	return $db_month;
}

sub is_numeric {

	my ($value) = @_;

    if ($value =~ /[A-Za-z]/) {
		return 0;
	} else {
    	return 1;
	}
}

## MAIN ##

%multipliers = create_multipliers();

my $tmp_account = '';
my $account = '';
my $in_trades = 0;
my $symbol = '';
my $contract = '';
my $in_account = 0;

while (<>) {

	chomp;

	# The account number line
    if (my ($token) = /\s+ACCOUNT NUMBER: (.+)/) {

    	# The account number is the last token in the line
       	my ($tmp_account) = (split /\s/, $token)[-1];

		# Check if the Account doesn't start with an RM,
        # we don't want to process the RM accounts
        # 2014-07-21 Now there are also MBFR accounts
        #if ($tmp_account =~ /^RM/ || $tmp_account =~ /^MBFR/) {
        #if ($tmp_account =~ /^690R/ || $tmp_account =~ /^698R/ || $tmp_account =~ /^MBFR/) {
		# Anything with an R is gonna be considered a related account
        if ($tmp_account =~ /R/) {
            $in_account = 0;
        } else {
            $in_account = 1;
        }

        # See if the account changed to get the new one and clean the vars
        if ($account ne $tmp_account) {

        	$account = $tmp_account;
			$in_trades = 0;
			$symbol = '';
			$contract = '';
        }

        next;
    }
	
	# The start of the open positions section
	if ($in_account && /O\s+P\s+E\s+N/ && /P\s+O\s+S\s+I\s+T\s+I\s+O\s+N\s+S/) {
		$in_trades = 1;
		next;
	}

	# The trade's line start with a F and a digit like F1 or F2
	# or with a date like 6/08/2
	if ($in_account && $in_trades && (/^\s*F\d/ || /^\s*\d{1,2}\/\d\d\/\d/)) {

		# Convert the spaces in the line into only one space
		my $line = $_;
		$line =~ s/[ \t]+/ /g;
		$line =~ s/^\s//;	# Deletes any space at the begining

		if ($line =~ /PUT|CALL/) {

			($symbol, $contract) = process_option($_);

		} elsif ($line =~ /(?:C|P)\s\d{1,2}(?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\d{2}\sICE\sENO\s\d{1,}/) {
			# ENO option special case.
			($symbol, $contract) = process_daily_option($_);

		} else {

			# The month is the 3rd token in that line, the year
			# is the fourth, get them and convert it into FLA
			# notation JAN 12 -> F12, etc.
			my ($col1, $col2) = (0, 0);
			if ($contract eq '') {

				if (/^\s*F\d/) {
					$col1 = 2;
					$col2 = 3;
				} else {
					$col1 = 3;
					$col2 = 4;
				}

				my ($month, $year) = (split /\s/, $line)[$col1, $col2];

				my $days = undef;

				if ($month =~ /\d/) {
					$days = $month;
					$col1++;
					$col2++;
					($month, $year) = (split /\s/, $line)[$col1, $col2];
				}
				
				$contract = convert_contract($month . $year, $days);
			}

			if ($symbol eq '') {

				my @tokens = (split(/\s/, $line));

				my $length = scalar(@tokens) - 3;

				for (my $i = $col2 + 1; $i < $length; $i++) {
					$symbol .= "$tokens[$i] ";
				}

				# Delete the last blank from the Symbol
				chop($symbol);

				# Delete numbers at the end of the Symbol
				$symbol =~ s/[\s\d.]+$//;
				$symbol =~ s/\s(SE|E|F|P|L|H|S|T|SG|G|D)\s*$//;
			}
		}

		next;
	}

	# The subtotal of the trades has the amount and a * at the right like 123*
	# The subtotal pattern is the trigger for printing
	if ($in_account && $in_trades && /^.+\s+CLOSE/ && $account ne '' && $contract ne '') {

		# If the positions are long or short has to be decided based on
		# the amount of spaces in front of the number

		my ($long, $short) = (0, 0);

		if (/\*[\d,\s]+\*/) {
			($long, $short) = /^\s+([\d,]+)\*\s+([\d,]+)\*/;
		} else {
			my ($spaces, $positions) = /^(\s+)([\d,]+)\*/;
			$positions =~ s/\,//;

			if (length($spaces) < 40) {
				$long = $positions;
			} else {
				$short = $positions;
			}
		}

		my ($tmp) = /(?:EX|LTD)-\s*(\d+\/\d+\/\d+)\s/;
		my $expiration = '1/1/2100';

		if (defined($tmp)) {
			$expiration = clean_date($tmp);
		} elsif ($contract =~ /\./) {
			$expiration = daily_contract_to_date($contract);
		}

        my ($settlement) = /CLOSE\s+([-0-9.]+(?:\s\d\/\d)?|CABINET|[A-Za-z.]+)/;

		if ($settlement eq 'CABINET' || !is_numeric($settlement)) {
			$settlement = 0.01;
		}

		$settlement =~ s/-//;

        # Parse fractions settlements.
        if ($settlement =~ /\//) {
    		$settlement = parse_number_fraction($settlement);
        }

		# Calculate the net from Long and Short, to avoid having values in both columns
    	# and do not print balanced accounts: Long - Short = 0

    	my $net = $long - $short;

    	if ($long != 0 || $short != 0) {

        	if ($long != $short) {

            	if ($net > 0) {
                	$long = $net;
                	$short = 0;
            	} else {
                	$long = 0;
                	$short = abs($net);
            	}

				# Clean the last portion of the symbol string
				$symbol =~ s/\s(SE|E|F|P|L|H|S|T|A|GE|SV|SF|GG)\s*$//;

				# Delete daily portion for DAX and E-STXX
        	    if ($symbol =~ /EUX\sDAX\sINDEX|EUX\sE-STXX/) {
            	    $contract =~ s/\.\d\d//;
            	}

				say "$account, $symbol, $contract, $long, $short, $settlement, $expiration";
        	}
    	}

		$symbol = $contract = '';

		next;
	}

	# The following pattern is the stop condition that put the in_trades flag to false.
	if (/BEGINNING BALANCE/) {
		$in_trades = 0;
		$symbol = $contract = '';
		next;
	}
}

## END MAIN ##

__END__
ICE USD INDX OPT,1
ICE COFFEE C OPT,1
