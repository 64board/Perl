#!/usr/bin/perl

# Getopt example.
# https://perldoc.perl.org/Getopt::Std
# jesus.aneiros@gmail.com
# 2021-12-28
  
use strict;
use warnings;

use Getopt::Std;
use File::Basename;
use feature 'say';

my $file_name = basename($0);

my %options = ();

getopts("i:oh", \%options);

if (defined($options{'h'})) {
    print_usage();
    exit 1;
}

if (!defined($options{'i'})) {
    print_usage();
    exit 1;
}

say "-i = $options{'i'}";
say "-o = $options{'o'}" if defined($options{'o'});
 
sub print_usage {
    say "Usage: $file_name -i <DB host ip number>";
    say "       $file_name -o Optional option";
    say "       $file_name -h Show this usage help.";
}

__END__
