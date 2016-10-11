#!/usr/bin/perl -w
#
use strict;
use warnings;
use Bio::SeqIO;

my %hash1 = ();
my %hash2 = ();
my %info = ();
my %names = ();
my %data = ();
my %locus = ();
my $number = 0;
my $alt1_mod = "";
my $alt2_mod = ""; 
my %positions_hash = ();

#Usage perl generate_Structure_inputv3.pl <positions_file <output_name>
# Run program from the previous folder of the $work folder, that is, if the folder is: $home/Samples/Structure_input/
# and Structure_input is $work, run it inside Samples, so it can access $work/$Syn/$folder/


my $folder = $ARGV[2] || die "Please provide file" ;
my $Syn = $ARGV[3] || die "Please provide file" ;
my $work = $ARGV[4] || die "Please provide file" ;
my $posi = $ARGV[0] || die "Please provide file" ;
open(FILE, "<$posi") || die "File $posi doesn't exist!!";

my $output = $ARGV[1]; 
open (OUTPUT, ">$output") || die "cannot open $output file: $!";

#Get all the files in the $folder that start with LIB*

my @FILES = glob("$work/$Syn/$folder/LIB*");
foreach my $file (@FILES) {
	open (IN, $file) or die "couldn't open $file";
	my @filename = split ("\/", $file); ## Splits path to file to extract the filename, NEEDS TO BE MOD
	while (my $line = <IN>) {
    	chomp $line;
		my ($contig, $position, $ref, $alt1, $alt2) = split ("\t", $line);
		if ($alt1 eq "A") {
			($alt1_mod = "1");
		} elsif ($alt1 eq "T") {
			($alt1_mod = "2");
		} elsif ($alt1 eq "G") {
			($alt1_mod = "3");
		} elsif ($alt1 eq "C") {
			($alt1_mod = "4");
		}
		if ($alt2 eq "A") {
			($alt2_mod = "1");
		} elsif ($alt2 eq "T") {
			($alt2_mod = "2");
		} elsif ($alt2 eq "G") {
			($alt2_mod = "3");
		} elsif ($alt2 eq "C") {
			($alt2_mod = "4");
		}
		
		# ./Syn_all_data_NBA/LIB12472/LIB12472_syn_all_data.txt
		#   	0		1		2	3  #position number 3

		my ($name) = $filename[3] =~ /(LIB.*)_syn_all.*$/;
		$info{$name}{$contig}{$position}{'pos1'} = "$alt1_mod";
		$info{$name}{$contig}{$position}{'pos2'} = "$alt2_mod";
		$names{$name} = "";
	}
		

	close IN;
}
	
while (my $line = <FILE>) {
    chomp $line;
    my ($contigs, $positions) = split ("\t", $line);
    
    foreach my $id (keys %names) {
    	if (exists $info{$id}{$contigs}{$positions}) {
    	} else {
    	 	$info{$id}{$contigs}{$positions}{'pos1'} = "-9";
    	 	$info{$id}{$contigs}{$positions}{'pos2'} = "-9";
    	}
    }
   	$positions_hash{$contigs}{$positions} = ""; 	 	
}
print OUTPUT "\t";

foreach my $sample (sort keys %info) {
	$data{$sample}{'alt1'} .= "$sample\t";
	$data{$sample}{'alt2'} .= "$sample\t";
	foreach my $con (sort keys %{$info{$sample}}) {
		foreach my $pos (sort keys %{$info{$sample}{$con}}) {
				my ($mod_contigs) = $con =~ /PST130_(\d+)/;
				if (exists $positions_hash{$con}{$pos}) {
					$locus{$con}{$pos} = "$mod_contigs"."_"."$pos\t";		
					$data{$sample}{'alt1'} .= "$info{$sample}{$con}{$pos}{'pos1'}\t";
					$data{$sample}{'alt2'} .= "$info{$sample}{$con}{$pos}{'pos2'}\t";
				}
			}
	}

}
foreach my $key1 (sort keys %locus) {
	foreach my $key2 (sort keys %{$locus{$key1}}) {
		++$number;
		print OUTPUT "$locus{$key1}{$key2}";
	}
}


foreach my $key (sort keys %data) {
	
	print OUTPUT "\n$data{$key}{'alt1'}\n$data{$key}{'alt2'}";
}

#print OUTPUT "\n";

print "$number\n";

close (OUTPUT);
exit;
