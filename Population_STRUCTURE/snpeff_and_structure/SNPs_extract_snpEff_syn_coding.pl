#!/usr/bin/perl -w

use strict;
use warnings;
use Bio::SeqIO;

#Extract synonymous coding SNPs


my $snpeff_out = $ARGV[0] || die "Please provide file" ;
open(FILE, "<$snpeff_out") || die "File $snpeff_out doesn't exist!!";

my %info = ();

print "Chromo	Position	Reference	Change	Change_type	Homozygous	Quality	Coverage	Warnings	Gene_ID	Gene_name	Bio_type	Trancript_ID	Exon_ID	Exon_Rank	Effect	old_AA/new_AA	Old_codon/New_codon	Codon_Num(CDS)	Codon_Degeneracy	CDS_size	Codons_around	AAs_around	Custom_interval_ID\n";

while (my $line = <FILE>) {
    chomp $line;
	my ($Chromo, $Position, $Reference, $Change, $Change_type, $Homozygous, $Quality, $Coverage, $Warnings, $Gene_ID, $Gene_name, $Bio_type, $Transcript_ID, $Exon_ID, $Exon_Rank, $Effect, $old_AA_new_AA, $Old_codon_New_codon, $Codon_Num_CDS, $Codon_Degeneracy, $CDS_size, $Codons_around, $AAs_around, $Custom_interval_ID) = split ("\t", $line);

#If you want the Non Synonymous SNPs, change the following by: "NON_SYNONYMOUS_CODING"
#If you want both non synonymous and synonymous, delete the following if-statement and just print all the lines.
	if ($Effect eq "SYNONYMOUS_CODING") {
		print "$line\n";
	}	
}

exit;
