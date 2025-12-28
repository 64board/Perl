#!/usr/bin/perl

# Parse a statement TXT file and extract the statement's date
# in format YYYYMMDD.
# janeiros@mbfcc.com, 2025-12-28

use strict;
use warnings;

use v5.010;

use feature 'say';

sub get_date {

    my ($date_line) = @_;

    my %months = (
        'JAN' => '01',
        'FEB' => '02',
        'MAR' => '03',
        'APR' => '04',
        'MAY' => '05',
        'JUN' => '06',
        'JUL' => '07',
        'AUG' => '08',
        'SEP' => '09',
        'OCT' => '10',
        'NOV' => '11',
        'DEC' => '12'
    );
	
    # The date is coming in the form of NOV 03, 2011 at the end of the line.
    if ($date_line =~
        /STATEMENT\sDATE:
        \s+
        (JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)   # Month
        \s+
        (\d{1,2})   # Day
        ,\s+
        (\d{4})     # Year
        \s*$        # End of line with optional space
        /x) {

        my ($month_name, $day, $year) = ($1, $2, $3);

        return sprintf "%04d%02d%02d", $year, $months{$month_name}, $day;

    } else {
        return undef;
    }
}

## MAIN ##

my $file_date = undef;

while (<>) {

    chomp;

    $file_date = get_date($_);

    if (defined($file_date)) {
        say $file_date;
        last;
    }
}

## END MAIN ##

__END__
