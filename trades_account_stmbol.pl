#!/usr/bin/perl

# Shows count of ICE TC trades by account and symbol.
# janeiros@mbfcc.com
# 2022.03.02 First version. Uses hash with 2 keys, account and symbol.
# 2023.08.22 Modified version using regular expresions for extractions.
 
use strict;
use warnings;

use 5.010;

use feature 'say';

use Getopt::Std;
use File::Basename;

sub print_usage {
    my $program_name = basename(shift);
    say "Usage: $program_name -f <Path to FIX tradesfile>";
    say "       $program_name -h Show this usage help.";
}

#my $FIELD_DELIMITER = '\|';
my $FIELD_DELIMITER = '\001';

# Hash with 2 keys: account and symbol.
my %trades = ();

my %options = ();

getopts("f:h", \%options);

if (defined($options{'h'})) {
    print_usage($0);
    exit 1;
}

if (!defined($options{'f'})) {
    print_usage($0);
    exit 1;
}

my $LOG_FILE = $options{'f'};

open(my $fh, "<", $LOG_FILE)
        or die "Can't open ${LOG_FILE}: $!\n";

while (<$fh>) {

    # Only Trade Capture Report lines.
    next if ! /35=AE/;

	chomp;

    my ($symbol) = /
        $FIELD_DELIMITER
        48=([^$FIELD_DELIMITER]+)
        /x;

    my ($leg1_symbol, $leg2_symbol) = $symbol =~ /
        ([^\-!]+)   # Leg 1 symbol. Don't capture ! at the end of outrights.
        (?:         # Leg 2 only exists in spreads.
        \-          # Spread separator.
        ([^\-]+)    # Leg 2 symbol, only in spreads.
        )?
        /x;

    my ($account) = /
        $FIELD_DELIMITER
        448=([^$FIELD_DELIMITER]+)
        $FIELD_DELIMITER
        447=D
        $FIELD_DELIMITER
        452=51
        /x;

    $trades{$account}{$leg1_symbol}++;
    $trades{$account}{$leg2_symbol}++ if defined($leg2_symbol);
    
}

# Print account ans symbol.
foreach my $a (sort keys %trades) {
    
    # Handle hash element as hash.
    foreach my $s (sort keys %{$trades{$a}}) {

        printf "%10s %30s %5d\n", $a, $s, $trades{$a}{$s};
    }
}

__END__
