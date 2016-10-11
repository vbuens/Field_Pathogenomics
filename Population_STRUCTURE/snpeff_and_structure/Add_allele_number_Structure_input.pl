#!/usr/bin/perl -w

use strict;

my $Str_file = $ARGV[0] || die "No Structure file";
my $output = $ARGV[1] || die "No output file";
my %h;
my $i = 0;

open (OUTPUT, ">$output") || die "cannot open $output file: $!";

open (STR, $Str_file) or die "couldn't open $Str_file";

while (<STR>){
	chomp;
    my @fields= split /\s/;
    if(!$fields[0]) {
    	print OUTPUT $_;
    	next;
    }
    my $lib = $fields[0];
    $i++;
    if($i >= 3){
    	$i = 1;
    }
    my $sample = $lib."_".$i;
    print OUTPUT "\t";
	print OUTPUT "\n";
	print OUTPUT $sample;
    for(1..$#fields){
	print OUTPUT "\t";
	print OUTPUT $fields[$_];
    }
}

#system("rm $Str_file");
