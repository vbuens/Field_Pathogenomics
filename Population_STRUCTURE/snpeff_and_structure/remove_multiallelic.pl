#!/usr/bin/perl -w

use strict;
use warnings;
use Bio::SeqIO;


my $structure_input = $ARGV[0] || die "Please provide input and output files\n";
my $biallelic_snp_file = $ARGV[1] || die "Please provide input and output files\n";
open(FILE, "<$structure_input") || die "File $structure_input doesn't exist!!\n";
open (OUT, ">$biallelic_snp_file") || die "Cannot create $biallelic_snp_file\n";
my $biallelic_count = 0;
my $multiallelic_count = 0;

while (my $line = <FILE>) {
    chomp $line;
    if ($line =~ /^\t.*$/) {
    	print OUT "$line\n";
    	next;
    }
    my @columns = split ("\t", $line);
    my $num_elements = @columns;
	my $info = "";
    for (my $x = 1; $x <$num_elements; $x++){
    	my $base_code = $columns[$x];
    	next if ($base_code eq "-9");
    	if ($info eq "") {
    		$info = $base_code;
    		next;
    	}
    	unless ($info =~ /$base_code/) {
    		$info .= $base_code;
    	}
    }
    if (length $info < 3) {
    	print OUT $line,"\n";
    	$biallelic_count++;
    } else {
    	$multiallelic_count++;
    }
}

print "biallelic=$biallelic_count\nmultiallelic=$multiallelic_count\n";

close FILE;
close OUT;

exit;
