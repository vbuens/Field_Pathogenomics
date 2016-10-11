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
    	next;
    }
    my @columns = split ("\t", $line1);
    my $line2 = <FILE>;
    chomp $line2;
    my @columns2 = split ("\t", $line2);
    my $num_elements = @columns;
    print "$columns[0]  ";

    for (my $x = 1; $x <$num_elements; $x++){
    	if ($columns[$x] == -9) {
    		print "0 ";
    	} elsif  ($columns[$x] == 1) {
    		print "A ";
    	} elsif  ($columns[$x] == 2) {
    		print "T ";
    	} elsif  ($columns[$x] == 3) {
    		print "G ";
    	} elsif  ($columns[$x] == 4) {
    		print "C ";
    	}
    	if ($columns2[$x] == -9) {
    		print "0  ";
    	} elsif  ($columns2[$x] == 1) {
    		print "A  ";
    	} elsif  ($columns2[$x] == 2) {
    		print "T  ";
    	} elsif  ($columns2[$x] == 3) {
    		print "G  ";
    	} elsif  ($columns2[$x] == 4) {
    		print "C  ";
    	}
    }
    print "\n";
}
    
    
exit;
