#!/usr/bin/perl -w
use strict;
use warnings;

my $Galaxy_17 = $ARGV[0] || die "Please provide blast top hit list" ;
open(FILE, "<$Galaxy_17") || die "File $Galaxy_17 doesn't exist!!";

while (my $line = <FILE>) {
	chomp $line;
	my ($contig, $position, $ref, $coverage, $alt, undef) = split ("\t", $line);
		if (($ref eq $alt) && ($coverage >= 2)) {
			print "$line\n";
		}
}
exit;
