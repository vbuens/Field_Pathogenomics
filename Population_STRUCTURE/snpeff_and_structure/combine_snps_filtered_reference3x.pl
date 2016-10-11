#!/usr/bin/perl -w

use strict;
use warnings;
use Bio::SeqIO;

#Used to modify gene based on SNPs - reads in output from "vcf


my $Reference = $ARGV[0] || die "Please provide file" ;
open(FILE, "<$Reference") || die "File $Reference doesn't exist!!";

my $filtered_snps = $ARGV[1] || die "Please provide file" ;
open(FILE2, "<$filtered_snps") || die "File $filtered_snps doesn't exist!!";

my %info = ();
my %alternative = ();

while (my $line2 = <FILE2>) {
    chomp $line2;
    my ($contig, undef, $position, $ref, $coverage, $alt, $stuff, $score) = split ("\t", $line2);
    my ($alt1, $alt2) = split ("", $alt);
    $info{$contig}{$position} = "$contig\t$position\t$ref\t$alt1\t$alt2";
	
}	


while (my $line = <FILE>) {
    chomp $line;
	my ($Chromo, $Position, $Ref, $coverage, $alt, $score) = split ("\t", $line);
	if (exists $info{$Chromo}{$Position}) {
	} else {
	
	$info{$Chromo}{$Position} = "$Chromo\t$Position\t$Ref\t$alt\t$alt";
	}
	
}

foreach my $contig (sort keys %info) {
	foreach my $position (sort keys %{$info{$contig}}) {	
		print "$info{$contig}{$position}\n";
	}
}
exit;
