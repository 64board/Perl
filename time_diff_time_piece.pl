#!/usr/bin/perl

# Prints time difference between 2 date & time values
# read from a file.
#
# One value has the form 2024-05-28 04:59:11
# other one is like transactTime=2024-05-28T16:38:21.000000000Z
# First time is Eastern time, second time is UTC.

# Uses Time::Piece and Time::Seconds which are part of the Perl core.

use strict;
use warnings;

use 5.010;
use feature 'say';

use Time::Piece;
use Time::Seconds;

# File with date time values.
open(my $fh, '<', '9892_stp.txt')
    or die("Error opening file: $!\n");

while (<$fh>) {

    chomp;

    # Extract raw values from file's lines.
    my ($log_time, $ts_time) = (split(/,/))[0,15];

    $log_time =~ s/\s/T/;
    
    # Add time zone data, EDT.
    $log_time .= ' -0400';
    
    # Use parsing from strptime to create Time::Piece.
    my $t1 = Time::Piece->strptime($log_time, "%FT%T %z");

    # Increase 4 hours UTC time difference.
    #$t1 += (4 * ONE_HOUR);

    # transactTime=2024-05-28T16:38:21.000000000Z
    ($ts_time) = $ts_time =~ 
        /transactTime=(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})/;

    # Add time zone data, UTC.
    $ts_time .= ' +0000';

    # Use parsing from strptime to create Time::Piece.
    my $t2 = Time::Piece->strptime($ts_time, "%FT%T %z");

    # Difference in seconds expressed as a Time::Piece object.
    my $time_diff = $t1 - $t2;

    use integer;
    my $minutes = $time_diff / 60;
    my $seconds = $time_diff % 60;

    if ($minutes > 0) {
        say "Log time:      $log_time";
        say "Transact time: $ts_time";
        say "Diff =         $minutes mins and $seconds secs";
    }

}

close($fh);

__END__