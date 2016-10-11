#!/usr/bin/perl -w
#
use strict;
use warnings;
use Bio::SeqIO;

my %info = ();

my $output = $ARGV[0];  # Name of the output positions file "Positions.txt"
my $direct = $ARGV[1];  # Working directory
my $Syn = $ARGV[2];		# Synonymous directory, where the files with the synonymous SNPs are

open (OUTPUT, ">$output") || die "cannot open $output file: $!";

# Open all the files located in the following path:
my @FILES = glob("$direct/$Syn/Filtered/LIB*");
foreach my $file (@FILES) {
	open (IN, $file) or die "couldn't open $file";
	while (my $line = <IN>) {
    	chomp $line;
		my ($contig, $pos_minus, $position, $ref, $cov, $alt1, undef, undef) = split ("\t", $line);
		$info{$contig}{$position} = "";
	}
		

	close IN;
}
	
# Print all the positions 

foreach my $con (sort keys %info) {
	foreach my $pos (sort keys %{$info{$con}}) {
			print OUTPUT "$con\t$pos\n";
				
	}
}

close (OUTPUT);
exit;
