#!/usr/bin/perl

use strict;
use warnings;

use feature 'say';

use Getopt::Std;
use File::Basename;

sub print_usage {
    
    my $script_name = shift;

    my $version = 'v2023.11.04';

    say "$script_name $version";
    say "$script_name: Extracts a token line from a CME STP log file using token number.";
    say "Usage: $script_name -n <Token counter number> -f <File to search>";
    say "       $script_name -h Show this usage help.";
}

my $script_name = basename($0);

my %options = ();

getopts("-f:n:h", \%options);

if (defined($options{'h'})) {
    print_usage($script_name);
    exit 1;
}

if (!defined($options{'f'})
    or !defined($options{'n'})) {
    print_usage($script_name);
    exit 1;
}

my $file_name = $options{'f'};
my $counter_search = $options{'n'};

my $token_portion = undef;

open(my $fh, '<', $file_name)
    or die "Error opening $file_name: $!\n";

while (<$fh>) {

    chomp;

    ($token_portion) = (
        /REQUEST_TOKEN:\s
        \[
        ($counter_search\|\d+\|[A-Za-z0-9=]+)
        \]
        \s*$/x
    );
    
    last if defined($token_portion);

}

close $fh;

if (defined($token_portion)) {
    say $token_portion;
} else {
    say STDERR "Error: ${counter_search} not found.";
}

__END__
