#!/usr/bin/perl -w

# Reads SNP_ratio file from the STDIN and  
# calls the genotype at each site so sites with 
# minor allele frequencey between hetero_freq_mini and hetero_freq_max
# are called heterozygous.
#
# Applies a coverage depth filter of mindepth (20x recommended)


use strict;
use File::Basename;

my $cmd = basename($0);

my $usage = "usage: $cmd mindepth hetero_freq_mini hetero_freq_max\n";
my $min_depth = shift or die $usage;
my $freq_min = shift or die $usage;
my $freq_max = shift or die $usage;

while(my $line = <STDIN>){
    
	chomp $line;
    $line =~ s/ //g;
    
	my @column = split /\t/, $line;
    my $chr = $column[0];
    my $pos = $column[1];
    my $posminus = $column[1]-1;
    my $refbase = $column[2];
    my $depth = $column[3];
	
    if( ($depth >= $min_depth) and $column[4] and $column[5] )
	{
	    my $freq = $column[5];
	    my @alt = split /,/, $column[4];
	    my @freqa = split /,/, $freq;
    
	    my @new_alt;
	    my @new_freq;
	    my $no_base =0;
	    my $gt="";
	    
			for(my $idx = 0; $idx<scalar(@freqa);$idx++)
			{
			    if($freqa[$idx] >= $freq_max )
				{
					if($alt[$idx] ne $refbase)
					{
					    @new_alt=();
					    $gt = "1/1";
					    push @new_alt, $alt[$idx];
					    push @new_alt, $alt[$idx];
					    push @new_freq, $freqa[$idx];
					    last;
					}
					else
					{
					    @new_alt=();
					    $gt = "0/0";
					    push @new_alt, $refbase;
					    push @new_alt, $refbase;
					    push @new_freq, $freqa[$idx];
					    last;
					}
				
				}
			
				elsif($freqa[$idx]>=$freq_min && $freqa[$idx] < $freq_max)
				{
					$no_base++ if($alt[$idx] ne $refbase);
					push @new_alt, $alt[$idx];
					push @new_freq, $freqa[$idx];
		    	}
			}
		    
		if($gt ne "1/1" && $gt ne "0/0")
		{
		    if(scalar(@new_alt) == 1)
			{
				my $b = join "", @new_alt;
				if($b ne $refbase)
				{
					$gt = "1/1";
				}
				else
				{
				    $gt = "0/0";
				    next;
				}
				print "$chr\t$posminus\t$pos\t$refbase\t$depth\t";
				my $f = join "", @new_freq;
				print $b.$b;
				print "\t$gt\t$f\n";
		    }
			elsif(scalar(@new_alt) > 1)
			{
				if(scalar(@new_alt) == 2)
				{
				    if($no_base == 2)
					{
						$gt = "1/2";
						print "$chr\t$posminus\t$pos\t$refbase\t$depth\t";
						print join "", @new_alt;
						my $f = join ",", @new_freq;
						print "\t$gt\t$f\n";
				    }
					else
					{
						$gt = "0/1";
						print "$chr\t$posminus\t$pos\t$refbase\t$depth\t";
						print join "", @new_alt;
						my $f = join ",", @new_freq;
						print "\t$gt\t$f\n";
				    }
				}
				else
				{
					$gt = "?";
					print "$chr\t$posminus\t$pos\t$refbase\t$depth\t";
					print join "", @new_alt;
					my $f = join ",", @new_freq;
					print "\t$gt\t$f\n";				
				}
			}
		}
		elsif($gt eq "1/1")
		{
		    print "$chr\t$posminus\t$pos\t$refbase\t$depth\t";
		    print join "", @new_alt;
		    my $f = join ",", @new_freq;
		    print "\t$gt\t$f\n";
		}
		
		elsif($gt eq "0/0")
		{
		    print "$chr\t$posminus\t$pos\t$refbase\t$depth\t";
		    print join "", @new_alt;
		    my $f = join ",", @new_freq;
		    print "\t$gt\t$f\n";			
		}
		
    }
}



