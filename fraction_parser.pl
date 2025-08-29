#!/usr/bin/perl

use strict;
use warnings;

use feature 'say';

# Use the GNU Multiple Precision Libary or the Pary library
# if they are available, if not fallback to pure Perl and
# don't break.
use Math::BigFloat try => 'GMP,Pari';

say Math::BigFloat->config->{lib};

sub parse_number_fraction {

    my ($s, $mode, $tick_size) = @_;
    
    $mode ||= 'financial';
    
    $s =~ s/^\s+|\s+$//g;

    # Match "base n/d" with ASCII only
    if (my ($base_str, $n_str, $d_str) = $s =~ /
        ^
        (               # Start of base group capture.
        [+-]?\d+        # Integer portion.
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

# --- Examples ---
say parse_number_fraction("240.27 1/2", "financial");           # 240.275
say parse_number_fraction("240.27 1/2", "financial", "0.005");  # 240.2725
say parse_number_fraction("240.27 1/2", "literal");             # 240.77
say parse_number_fraction("240 3/8", "financial", "0.25");      # 240.09375
say parse_number_fraction("2.07 1/2", "financial");             # 2.075

__END__