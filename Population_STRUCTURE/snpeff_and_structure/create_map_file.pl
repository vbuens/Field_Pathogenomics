#!/usr/bin/perl -w

use strict;
use warnings;
use Bio::SeqIO;

#Used to modify gene based on SNPs - reads in output from "vcf

my $structure_input = $ARGV[0] || die "Please provide file" ;
open(FILE, "<$structure_input") || die "File $structure_input doesn't exist!!";


while (my $line1 = <FILE>) {
    chomp $line1;
    if ($line1 =~ /^\t.*$/) {
    	my @info = split ("\t", $line1);
    	my $num_elements = @info;
    	for (my $x = 1; $x < $num_elements; $x++) {
    		my ($contig, $position) = split ("_", $info[$x]);
    		
    		print "$contig snp$x $position\n";
    	}
    }
}
    
    
exit;
