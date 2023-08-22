#!/usr/bin/perl

# Shows duplicated trades based on trade ID.
# janeiros@mbfcc.com
# 2023.08.23 First version.

use strict;
use warnings;

use 5.010;

use feature 'say';

my %trades_id = ();

while (<>) {

    next if ! /INSERT/;

    chomp;

    my $trd_id = (split(/,/))[20];

    $trd_id =~ s/^\s*\'|\'$//g;

    if (defined($trades_id{"$trd_id"})) {
        $trades_id{"$trd_id"}{'count'}++;
        $trades_id{"$trd_id"}{'trades'} = $trades_id{"$trd_id"}{'trades'} . "\n" . $_;
    } else {
        $trades_id{"$trd_id"} = { 'count' => 1, 'trades' => $_ };
    }
}

my $count = 1;
foreach my $k (sort keys %trades_id) {

    if ($trades_id{"$k"}{'count'} > 1) {
        say "\n$count. $k";
        say $trades_id{"$k"}{'trades'};
        $count++;
    }
}

__END__
