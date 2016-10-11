#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Long;
use Cwd;
=pod
This sript  or each gene.

->get whole genome consensus sequence

->cds alignmnets

Developed by KY
10-Nov-2011, at IBRC.
=cut


my($Command) = basename($0);

sub usage(){
    my($msg)=@_;
    if($msg){print STDERR "$msg\n";}
    print STDERR "Usage: $Command Option\n";
    print STDERR "Option is \n";
    print STDERR " -p(refix) String:    (required) common output prefix.\n";
    print STDERR " -a(ln) txt file (required)\n";  
    print STDERR " -s(np) txt file (required)\n";   
    print STDERR " -gf(f3) file name\n";
    print STDERR " -o(utput) directory \n";
    exit(0);
}
if(scalar(@ARGV)==0){&usage();}

print STDERR "\n";
print STDERR "command line is:\n    $Command @ARGV\n";

#===============================================================================
my $Prefix="";
my $aln="";
my $snp="";
my $Help="";
my $Gff3="";
my $outdir="";
GetOptions(
    'prefix=s' => \$Prefix,
    'aln=s' => \$aln,
    'gff3=s' => \$Gff3,
    'snp=s' => \$snp,
    'output=s' => \$outdir,
    'help' => \$Help,
) or &usage();
&usage() if $Help;

# error check
if ($Prefix eq "") { &usage("need Prefix, exit."); }
if ($aln eq "") { &usage("need aln txt file, exit."); }
if ($snp eq "") { &usage("need snp file, exit."); }

print STDERR "Options:\n";
print STDERR "    Prefix=$Prefix\n";
print STDERR "    aln txt=$aln\n";
print STDERR "    snp txt=$snp\n";
print STDERR "    output Dir=$outdir\n";
my %Data_h=();

#global variables
my %Alignment_h=();
my %snp_h=();

print STDERR "Now input alignment file....\n";
&input_vcf_all($aln);
&Get_CDS_alignment();

#===============================================================================

sub Get_CDS_alignment(){
    #input gff file;
    my $previous_cds_id;
    my $previous_strand;
    my %CDS_alignment_h;

    open OUTPUT, ">$outdir/${Prefix}_consensus_cds.fa" or die "cannot create the output file\n";
    print STDERR "input coordinate file......\n";
    open IN, $Gff3 or die "cannot open the $Gff3\n";

    while(<IN>){
        chomp;
	my (@line) = split "\t";
	next if(/^##/);

	#mRNA check;
	if($line[2]=~/mRNA/){

	    if(defined $previous_cds_id){
		my $seq_ar = &cds_seq(\%CDS_alignment_h,$previous_cds_id, $previous_strand);
		print OUTPUT ">$previous_cds_id\n";
                #my $i=0;
                my $cds_seq='';
		print OUTPUT @{$seq_ar};
                print OUTPUT "\n";
	    }

	    $line[8] =~ /^ID=(\S+)/;
	    my $id = $1;
	    
	    %CDS_alignment_h=();
	    $previous_cds_id = $id;
	    $previous_strand = $line[6];
	}
	
	#cds_check--------------------------------------------------------------
	if($line[2]=~/exon/){    
	
            my ($chr) = $line[0];
            my ($start_position) = $line[3];
            my ($stop_position) = $line[4];

	    for(my $pos=$start_position; $pos<$stop_position+1; $pos++){
                if(exists $Alignment_h{$chr}{$pos}){
		    $CDS_alignment_h{$pos}=$Alignment_h{$chr}{$pos};
                }else{
		    $CDS_alignment_h{$pos}="?";
		}
	    }
	}
    }
    my $seq_ar = &cds_seq(\%CDS_alignment_h,$previous_cds_id, $previous_strand);
    print OUTPUT ">$previous_cds_id\n";
    print OUTPUT @{$seq_ar};
    print OUTPUT "\n";
    close OUTPUT;
  
    close IN;
}


#-------------------------------------------------------------------------------
sub cds_seq(){
    my ($CDS_alignment_href, $id, $strand) = @_;
    my @data=();
    if($strand eq "+"){
	my $pos=0;
	my $aa_pos=0;
	foreach my $line (sort {$a<=>$b} keys %{$CDS_alignment_href}){
            push @data, $CDS_alignment_href->{$line};
            
        }
    }else{
	my $pos=0;
	my $aa_pos=0;
	foreach my $line (sort {$b<=>$a} keys %{$CDS_alignment_href}){
	    
	    $CDS_alignment_href->{$line} =~ tr/ACGTRYSWKMBDHV/TGCAYRSWMKVHDB/;
	    
            push @data, $CDS_alignment_href->{$line};
	}
	
    }
    return \@data;
}


#-------------------------------------------------------------------------------

sub input_vcf_all(){
    my ($infile) = @_;
    open IN, $infile or die "cannot open the $infile\n";
    my $id = "";
    my $pos = 0;

    while(<IN>){
        chomp;
	#next if(/^#/);
	my @column = split /\t/;
	#print "@column\n";
	my $chr = $column[0];
	my $pos = $column[1];
	$Alignment_h{$chr}{$pos}=$column[4];
    }
    &input_vcf($snp);
}

#-------------------------------------------------------------------------------

sub input_vcf(){
    
    my ($infile) = @_;
    open IN, $infile or die "cannot open the $infile\n";
    my $id = "";
    my $pos = 0;

    while(<IN>){
        chomp;
	#next if(/^#/);
	my @column = split /\t/;
	#print "@column\n";
	my $chr = $column[0];
	my $pos = $column[2];
	my $ref = $column[3];
	my $alt = $column[5];
	my $gt = $column[6];
	my $base = $ref;
	if($gt eq "1/1"){
		my @base = split "", $alt;
		$Alignment_h{$chr}{$pos}=$base[0];
	    #$base = $alt;
	}elsif($gt eq "0/0"){
	    $Alignment_h{$chr}{$pos}=$ref;
	}else{
	    #if($gt eq "1/2" || eq "0/1"){
		my @base = split "", $alt;
		my $gtbase = join "", @base;
		$base = &hetero($gtbase);
	    #}else{
		#my @base = ($ref, $alt);
	
		#my $gtbase = join "", @base;
		#$base = &hetero($gtbase);
	    #}
	    $Alignment_h{$chr}{$pos}=$base;
	}
	}
    close IN;
}


sub hetero(){
    my ($gt) = @_;
    
    my %hetero_mark = (
    "AC" => "M","CA" => "M","AG" => "R","GA" => "R","AT" => "W","TA" => "W","CG" => "S","GC" => "S","CT" => "Y","TC" => "Y","GT" => "K","TG" => "K",
    );
    $gt = uc $gt;
    my $base = "?";
    $base = $hetero_mark{$gt} if(exists $hetero_mark{$gt});
    return $base;
}
