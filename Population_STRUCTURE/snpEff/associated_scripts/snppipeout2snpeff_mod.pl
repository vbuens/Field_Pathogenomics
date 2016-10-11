#!/usr/bin/perl -w
use strict;

while(<>){
    chomp;
    
    my @a = split "\t";
    my $chr = $a[0];
    my $pos = $a[2];
    my $ref = $a[3];
    my $gt = uc $a[5];
    my $geno = $a[6];
    my $type = $a[10];
    my $strand = $a[14];
#M=A/C, R=A/G, W=A/T, S=C/G, Y=C/T and K=G/T.
	if ($type eq "exon") {
   		my $out ="";
    	if($geno ne "0/0" && $geno ne "1/1" && $geno ne "?"){
        	if($gt eq "AC" || $gt eq "CA"){
            	$out = "M";
            	print "$chr\t$pos\t$ref\t$out\t$strand\n";
        	}elsif($gt eq "AG" || $gt eq "GA"){
            	$out = "R";
            	print "$chr\t$pos\t$ref\t$out\t$strand\n";
        	}elsif($gt eq "AT" || $gt eq "TA"){
            	$out = "W";
            	print "$chr\t$pos\t$ref\t$out\t$strand\n";
        	}elsif($gt eq "CG" || $gt eq "GC"){
            	$out = "S";
            	print "$chr\t$pos\t$ref\t$out\t$strand\n";
        	}elsif($gt eq "CT" || $gt eq "TC"){
            	$out = "Y";
            	print "$chr\t$pos\t$ref\t$out\t$strand\n";
        	}elsif($gt eq "GT" || $gt eq "TG"){
            	$out = "K";
            	print "$chr\t$pos\t$ref\t$out\t$strand\n";
        	}else{
            	next;
        	}
    	}elsif($geno eq "1/1"){
			my @base = split //, $gt;
        	if($base[0] eq $ref){
            	$out = $base[1];
        	}else{
            	$out = $base[0];
        	}
        	print "$chr\t$pos\t$ref\t$out\t$strand\n";
    	}
    }
}
