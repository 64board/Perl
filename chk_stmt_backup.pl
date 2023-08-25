#!/usr/bin/perl

# Check Stone and Advantage reports backup folders.
# janeiros@mbfcc.com
# 2023.08.22 First version.
# 2023.08.23 Version that checks folder dates to detect missing or extra directories,
# also uses current year and month in case they are not provided.
# 2023.08.25 Sort directories before iterating through them.
 
use strict;
use warnings;

use v5.10;

use feature 'say';

use Getopt::Std;
use File::Basename;
use DateTime;

sub print_usage {
    my $program_name = basename(shift);
    say "Usage: $program_name -c clearing <adv|sto> -p <path> [-y <year>] [-m <month>]";
    say "       $program_name -h Show this usage help.";
}

# Get command line parameters.
sub get_options {

    my %options = ();

    getopts("c:p:y:m:h", \%options);

    if (defined($options{'h'})) {
        print_usage($0);
        exit 1;
    }

    if (!defined($options{'c'})
        or !defined($options{'p'})
        or $options{'c'} !~ /adv|sto/i)
    {
        print_usage($0);
        exit 1;
    }

    my $clearing = $options{'c'};
    my $path = $options{'p'};
    my $year = $options{'y'};
    my $month = $options{'m'};

    # Take care of optional parameters.
    # Do some validations of the arguments.
    
    if (!defined($year)) {
        my $dt = DateTime->now();
        $year = $dt->year;
    } elsif ($year !~ /\d{4}/) {
        say "Error: year should be 4 digits. Argument was $year.";
        print_usage($0);
        exit 1;
    }

    if (!defined($month)) {
        my $dt = DateTime->now();
        $month = $dt->month;
    } elsif ($month !~ /(?:0?[1-9]|[10-12])/) {
        say "Error: month should be 1 or 2 digits, from 1 to 12. Argument was $month.";
        print_usage($0);
        exit 1;
    }

    # Take care of months argument with 1 digit, directory representations use 2 digits for month.
    $month = sprintf "%02d", $month;

    return $clearing, $path, $year, $month;
}

# Check the file name using a matching function passed as an argument.
sub check_dir {

    my ($path, $match_sub) = @_;

    my $date = basename $path;

    opendir(my $dh, $path)
        or return 0;

    my $CHECKS_NEEDED = 5;
    my $checks_found = 0;

    while (readdir $dh) {

        # Using sub reference for match checking.
        if ($match_sub->($_, $date)) {
            $checks_found++;
        }
    }

    closedir $dh;

    return $checks_found == $CHECKS_NEEDED;
}

sub file_match_adv {

    my ($file, $date) = @_;

    return $file =~ /
        (?:
        STM4_M58_${date}.(?:txt|pdf)
        |
        adv-accounts.csv
        |
        adv-cgenrc517-${date}.csv
        |
        adv-mbfmrg-${date}.csv
        )
        /ix;
}

sub file_match_sto {

    my ($file, $date) = @_;

    return $file =~ /
        (?:
        curr-sto-cgenrc517-${date}.csv
        |
        dstm\d{6}.txt
        |
        sto-accounts.csv
        |
        sto-cgenrc517-${date}.csv
        |
        sto-mbfmrg-${date}.csv
        )
        /ix;
}

# Creates a list of weekdays for a certain month and year.
# It will be use to detect missing directories.
sub generate_dates {

    my ($year, $month) = @_;
    my @dates;

    # Convert to integer.
    $month += 0;

    my $dt = DateTime->new(year => $year, month => $month, day => 1);

    while ($dt->month == $month) {

        # No weekend dates.
        if ($dt->day_of_week < 6) {
            push @dates, $dt->strftime('%Y%m%d');
        }
        $dt->add(days => 1);
    }

    return @dates;
}

## main ##

my ($clearing, $path, $year, $month) = get_options();

say "Checking $clearing files in $path for year $year and month $month ...";

opendir(my $dh, $path)
    or die "Can't open $path: $!\n";

my $count_bad = 0;
my $found = 0;

my @dates = ();

# Hash with dates as keays and 1 as values.
my %dates_calc = map { $_ => 1 } generate_dates($year, $month);

foreach (sort readdir $dh) {

    my $directory = $_;

    # Check it is a directory and it matches year and date.
    if (/$year$month/
        and -d "$path/$directory") {

        # A particular date was found as a directory.
        $found++;

        say "Checking files in $path/$directory ...";

        # Filename matching subroutine.
        my $sub_match = $clearing eq 'adv' ? \&file_match_adv : \&file_match_sto;

        if (check_dir("$path/$directory", $sub_match)) {

            say 'All files were found!';
            
            # Check date looking for missing or extra directories in the backup.
            if (defined($dates_calc{$directory})) {
                delete $dates_calc{$directory} ;
            } else {
                push @dates, $directory;
            }

        } else {
            say "Missing data files!";
            $count_bad++;
        }
    }
}

closedir $dh;

if (!$found) {
    say "\nNo directories with data files found!";
} elsif ($count_bad) {
    say "\nThere are problems!";
} else {

    # Hash should not contain any dates, all should be deleted during matching.
    # Any existing date means a missing data directory.
    if (keys %dates_calc) {
        say 'Following dates are missing:';
        foreach my $d (sort keys %dates_calc) {
            say $d;
        }
    } elsif (@dates) {
        say 'There are extra date directories:';
        foreach my $d (@dates) {
            say $d;
        }
    } else {
        say "\nAll good!";
    }
    
}

__END__
