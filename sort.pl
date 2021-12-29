#!/usr/bin/perl

# Sort function.
# jesus.aneiros@gmail.com
# 2021-12-28
 
use strict;
use warnings;

use feature 'say';

# Auxiliary function to sort by symbol and contract.
# Parameter has the form SYMBOL|MYY.
# Month values can be F, G, H, J, K, M, N, Q, U, V, X, Z.
# A contract has the form of F21, G21, H21, J21, F22, etc.
# It changes the contract from MYY to YYM and then sort lexicographically,
# symbol first then contract.
sub by_symbol_contract {
    my ($a_symbol, $a_contract) = split /\|/, $a;
    my ($b_symbol, $b_contract) = split /\|/, $b;

    # Move year to front of string, MYY to YYM.
    $a_contract = substr($a_contract, 1) . substr($a_contract, 0, 1);
    $b_contract = substr($b_contract, 1) . substr($b_contract, 0, 1);

    return ($a_symbol cmp $b_symbol) || ($a_contract cmp $b_contract);
}

sub separator {
    say '-' x 6;
}

my %contracts = ();

say 'Original hash order';

while (<DATA>) {
    
    chomp;

    $contracts{$_}++;

    say "$_";

}

separator();

say 'Default sort function';

foreach my $k (sort keys %contracts) {

    say "$k";
}

separator();

say 'Using substring in anonymous in-line subroutine';

foreach my $k (
    sort {
	substr($a, 0, 2) . # symbol
	substr($a, 4, 2) . # year
	substr($a, 3, 1)   # month
	cmp 
	substr($b, 0, 2) . # symbol
	substr($b, 4, 2) . # year
	substr($b, 3, 1)   # month
    } keys %contracts)
{
    say "$k";
}

separator();

say 'Using split and join in anonymous in-line subroutine';

foreach my $k (
    sort { join('', (split //, $a)[0,1,4,5,3]) cmp join('', (split //, $b)[0,1,4,5,3]) }
    keys %contracts)
{
    say "$k";
}

separator();

say 'Using user defined subroutine';

foreach my $k (
    sort by_symbol_contract
    keys %contracts)
{
    say "$k";
}

__END__
VX|F19
VX|F20
GC|F21
VX|H19
VX|G19
CL|G21
CL|G22
CL|H21
CL|J21
CL|K21
CL|K20
CL|M21
CL|N21
CL|U21
CL|Z21
CL|X21
CL|V21
CL|Q21
