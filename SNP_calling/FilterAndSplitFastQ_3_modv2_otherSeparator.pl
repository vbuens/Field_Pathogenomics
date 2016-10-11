#!/usr/bin/perl -w

#This script is designed to qc the Illumina sequence reads when output into two read files, 
# one for left-handed reads the other with left-handed reads.
#Do not use "." in output file name, seems to interfere with opening the OUT file.
#Prints the two halves as separate files for fastq.

use strict;
use warnings;

use lib '/tgac/workarea/collaborators/cabreral/PERL_LIBS';
use Solexa::Parser;
use Solexa::Fastq;

my $infileL = shift or die; #the left infile in fastq (/1)
my $infileR = shift or die; #the right infile in fastq (/2)
my $outfileL = shift or die; #outfile for good reads
my $outfileR = shift or die; #outfile for good reads
my $readLength = shift or die; #single-end read-length
my $format = shift or die; #'fasta' for 'fastq'

if ($format ne "fasta" && $format ne "fastq")
{
	warn "The given format \'$format\' is invalid.\nPlease use 'fasta' or 'fastq'.\n";
	exit;
}

#open the left and right files
open (LEFT, ">$outfileL") or die;
open (RIGHT, ">$outfileR") or die;


#count how many reads are used (and not used)
my $written = 0;
my $notWritten = 0;

#store the base name of any bad reads
my %badReads;

#open the left-handed infile
my $parserL = new Parser(-file=>$infileL, -format=>'fastq');

while (my $fastq = $parserL->next)
{
	#get the sequence
	my $seq = $fastq->seq;
	#get the base name of the sequence
	my $lid = $fastq->id;
	my ($id, $side) = split(/\ /, $lid);
	
	#get the length of it
	my $length = length($seq);
	#check to see if it's the correct length and contains no Ns
	if ($length != $readLength || $seq =~ m/N/i)
	{
		#if it does, add it to the bad reads hash
		$badReads{$id}++;
	}
}

print "finished analysing the left reads\n";

#do the same with the right-handed reads
my $parserR = new Parser(-file=>$infileR, -format=>'fastq');

while (my $fastq = $parserR->next)
{
	my $seq = $fastq->seq;
	my $rid = $fastq->id;
	my ($id, $side) = split(/\ /, $rid);
	
	my $length = length($seq);
	if ($length != $readLength || ($seq =~ m/N/i))
	{
		$badReads{$id}++;
	}
}

print "finished analysing the right reads\n";

#now, go through the files again and take out the bad reads

$parserL = new Parser(-file=>$infileL, -format=>'fastq');
$parserR = new Parser(-file=>$infileR, -format=>'fastq');
while (my $fastqL = $parserL->next)
{
	
	#get the base name of the left sequence
	my $left_id = $fastqL->id;
	my ($lid, $lside) = split(/\ /, $left_id);
	
	#get the base name of the right sequence
	my $fastqR = $parserR->next;
	my $right_id = $fastqR->id;
	my ($rid, $rside) = split(/\ /, $right_id);
	#make sure they're all in order and the parsed names are the same
	#To have exactly the same id without taking the 1 or 2 read
	my ($L, $read) = split(/\./, $lid);
	my ($R, $read) = split(/\./, $rid);
	
	if ($L ne $R)
	{
		warn "The sequences are not in order!!!\n";
		exit;
	}
	#check to see if it is a good read
	if (!exists($badReads{$lid}))
	{
		if ($format eq 'fastq')
		{
			#change quality scores from Solexa to Sanger
			#$fastqL->quals_to_sanger;
			#$fastqR->quals_to_sanger;
			#if all is OK, the split the fastq sequence....
			
			#...and write the appropriate side to the corresponding file
			print LEFT $fastqL->write;
			print RIGHT $fastqR->write;
			$written++;
		}
		if ($format eq 'fasta')
		{
			print OUT ">$left_id\n";
			print OUT $fastqL->seq, "\n";
			print OUT ">$right_id\n";
			print OUT $fastqR->seq, "\n";
			$written++;
		}
	}
	else
	{
		$notWritten++;
	}
}
print "finished writting the  reads\n";

print "Total written = $written\nTotal not written = $notWritten\n";

