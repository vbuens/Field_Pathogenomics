#!/usr/bin/perl -w

use strict;
use File::Basename;
my $cmd = basename($0);
my $usage = "$cmd prefix tab.txt";
my $prefix = shift or die $usage;
my $file = shift or die $usage;
my $outdir = shift or die $usage;

open IN, $file or die "cannot open $file\n";
open OUTPUT, ">$outdir/${prefix}_ggplot2input_allele_frequency.txt";
my %rh = ("1" =>"first", "2" => "second", "3" => "third");
print OUTPUT "freq\trank\tsample\n";
my $first;
my $second;
while(<IN>){
    chomp;
    my @a = split /\t/;
    my @freq = split /,/, $a[7];
    if(scalar @freq > 1){
        my $rank = 1;
        foreach my $f (sort {$b<=>$a} @freq){
            if($rank==1){
                print  OUTPUT "$f\t$rh{$rank}\t$prefix\n";
            }elsif($rank==2 && $f <= 0.5){
                print  OUTPUT "$f\t$rh{$rank}\t$prefix\n";
            }elsif($rank==3 && $f <= 0.5){
                print  OUTPUT "$f\t$rh{$rank}\t$prefix\n";
            }else{
                print "$_\n";
            }
            $rank++;
        }
    #}else{
        #if($a[6] eq "1/1"){
         #   $a[7]=~s/ //g;
          #  my $f = 1-$a[7];
           # print  OUTPUT "$a[7]\t$rh{1}\t$prefix\n";
            #print  OUTPUT "$f\t$rh{2}\t$prefix\n";
        #}
    }
}
close IN;
