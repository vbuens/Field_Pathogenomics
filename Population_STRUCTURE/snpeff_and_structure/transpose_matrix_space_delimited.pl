#!/usr/bin/perl -w
#
use strict;
use File::Basename;

my $cmd = basename($0);
my $usage = "usage: $cmd space-delimited file";
my $info = $ARGV[0] || die $usage ;
open(FILE, "<$info") || die "File $info doesn't exist!!";
my %h;
my @positions;
my @sample;
my $linecount=1;
while (<FILE>) {
    chomp;
    my @fields= split /\s/;
    if(!$fields[0]) {
    	@positions = @fields;
    	shift @positions;
 		#print STDERR @positions;
    	#print STDERR "\n";    	
    	next;
    }
    my $sample = $fields[0];
    push @sample, $sample;
    for(1..$#fields){
	push @{$h{$sample}}, $fields[$_];
    }
}

#       0   1   2
#value	4	-9	1
#value	4	2	2
#value	4	-9	3
#
#

print "\t";
print join "\t", @sample;
print "\n";
for (0..$#positions) {
	my $flag=0;
	my @fields;
	print $positions[$_];
	foreach my $sample (@sample){
	    print "\t";
	    print $h{$sample}[$_];
	}
	print "\n";
}

