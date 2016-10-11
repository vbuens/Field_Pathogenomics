#!/usr/bin/perl -w

use strict;
use warnings;
use Bio::SeqIO;

# Extract SNPs with 20x coverage that are non-/synonymous sites.
# Open SnpEff file with all the synonymous sites.
# Compare the synonymous sites to the SNPs_20x file, and if they are there, extract them.
# The output is a file with all the 20x SNPs that are synonymous sites.


my $snpeff_out = $ARGV[0] || die "Please provide file" ;
open(FILE, "<$snpeff_out") || die "File $snpeff_out doesn't exist!!";

my $SNPs_20x = $ARGV[1] || die "Please provide file" ;
open(FILE2, "<$SNPs_20x") || die "File $SNPs_20x doesn't exist!!";

my %info = ();

while (my $line2 = <FILE2>) {
    chomp $line2;
    my ($contig, undef, $position, $ref, $coverage, $alt, undef, undef) = split ("\t", $line2);
    $info{$contig}{$position} = $line2;
	
}	



while (my $line = <FILE>) {
    chomp $line;
	my ($Chromo, $Position, $Reference, $Change, $Change_type, $Homozygous, $Quality, $Coverage, $Warnings, $Gene_ID, $Gene_name, $Bio_type, $Transcript_ID, $Exon_ID, $Exon_Rank, $Effect, $old_AA_new_AA, $Old_codon_New_codon, $Codon_Num_CDS, $Codon_Degeneracy, $CDS_size, $Codons_around, $AAs_around, $Custom_interval_ID) = split ("\t", $line);
	if (exists $info{$Chromo}{$Position}) {
		print "$info{$Chromo}{$Position}\n";
	#} else {
	#	print "$line doesnt exist\n"
	}
	
}

exit;
