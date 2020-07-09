#!/bin/bash
#Usage: bash SNPpipeline.sh LIB100
#you need to be in the parental folder that contains the folder with the data to be analysed. For example, if the data is called 'LIB100' and is found within 'Dir/RNAseq' folder (~HOME/Dir/RNAseq/LIB100), the starting folder should be RNAseq.
#The folder with the data should contain the raw reads (paired end) with R1.fastq AND R2.fastq suffix (Example: LIB100/Data_R1.fastq; LIB100/Data_R2.fastq) 
 

LENGTH_READS=101 #Default value for the length of the reads.

while [[ $# -gt 1 ]]
do
	key="$1"
	
	case $key in
	    -n|--NameofLibrary) #Name of the directory, for example: LIBOakley
	    LIBRARY="$2"
	    shift # past argument
	    ;;
	    -g|--genome) #Give the directory where the indexed reference genome is.
	    GENOME="$2"
	    shift # past argument
	    ;;
	    -l|--LengthofReads) #Give the length of the reads. This is 101 by default.
	    LENGTH_READS="$2" 
	    shift # past argument
	    ;;
	    *) echo "Usage: SNPpipeline.sh -n LIBname -g Path/to/Genome -l length_reads. Unkown option: $1 " >&2 ; exit 1
	            # unknown option
	    ;;
	esac
	shift # past argument or value
done

if [ -z $LIBRARY ]; then  echo "No library directory given! Usage: SNPpipeline.sh -n LIBname -g Path/to/Genome -l length_reads"; exit 1; fi
if [ -z $GENOME ]; then   echo "No reference genome given! Usage: SNPpipeline.sh -n LIBname -g Path/to/Genome -l length_reads"; exit 1 ; fi

echo LIBRARY  = "${LIBRARY}"
echo GENOME   = "${GENOME}"
echo LENGTH OF READS  = "${LENGTH_READS}"


#First step will be identify the raw reads accordingly. Change this to match the name of your data files.

fasR=$(ls $LIBRARY/*R1.fastq)
fasL=$(ls $LIBRARY/*R2.fastq)

if [ ! -f $fasR ] || [ ! -f $fasL ]	#If Reference Genome is not defined, exit.
then
        echo Reads could not be found inside of the given directory: "${LIBRARY}"; exit 1
fi



####################################
###### 		SNP calling 	  ###### 
####################################


#Filter reads. Verify the length of the reads and change it in the command line. In this case, the length of the reads is 101.
                
mkdir $LIBRARY/Filter 		#output folder for the filtered reads
source perl-5.22.1;
perl SCRIPTS/FilterAndSplitFastQ_3_modv2.pl $fasR $fasL $LIBRARY/Filter/$LIBRARY\_R1.fastq $LIBRARY/Filter/$LIBRARY\_R2.fastq $LENGTH_READS fastq
               
#If the sequences contains adaptors, remove them, if not, skip this step. -f represents the starting nucleotide of which the sequence without adaptor starts.
#Verify if the data comes from Illumina: -Q33

source fastx_toolkit-0.0.13.2
fastx_trimmer -f14 -i $LIBRARY/Filter/*R1.fastq -o $LIBRARY/Filter/$LIBRARY\_trim_R1.fastq -Q33
fastx_trimmer -f14 -i $LIBRARY/Filter/*R2.fastq -o $LIBRARY/Filter/$LIBRARY\_trim_R2.fastq -Q33

#Determine the quality of the sequences and plot it
mkdir $LIBRARY/Statistics        		
mkdir -p $LIBRARY/Plots/Quality_plots
mkdir $LIBRARY/Plots/Nt_distribution           

fastx_quality_stats -i $LIBRARY/Filter/$LIBRARY\_trim_R1.fastq -o $LIBRARY/Statistics/$LIBRARY\_R1_stats.txt -Q33
fastx_quality_stats -i $LIBRARY/Filter/$LIBRARY\_trim_R2.fastq -o $LIBRARY/Statistics/$LIBRARY\_R2_stats.txt -Q33

fastq_quality_boxplot_graph.sh -i $LIBRARY/Statistics/$LIBRARY\_R1_stats.txt -o $LIBRARY/Plots/Quality_plots/$LIBRARY\_R1_quality.png
fastq_quality_boxplot_graph.sh -i $LIBRARY/Statistics/$LIBRARY\_R2_stats.txt -o $LIBRARY/Plots/Quality_plots/$LIBRARY\_R2_quality.png
                
fastx_nucleotide_distribution_graph.sh -i $LIBRARY/Statistics/$LIBRARY\_R1_stats.txt -o $LIBRARY/Plots/Nt_distribution/$LIBRARY\_R1_nt_distr.png
astx_nucleotide_distribution_graph.sh -i $LIBRARY/Statistics/$LIBRARY\_R2_stats.txt -o $LIBRARY/Plots/Nt_distribution/$LIBRARY\_R2_nt_distr.png

#Align against the reference genome (previously indexed).

source tophat-2.1.0; source bowtie-2.2.6; source samtools-0.1.19; 
tophat -r 200 -o $LIBRARY/top_hat $GENOME $LIBRARY/Filter/$LIBRARY\_trim_R1.fastq $LIBRARY/Filter/$LIBRARY\_trim_R2.fastq
                
#Once the alignment is done, proceed to sort and index the output file (the one that contains the aligned reads)
                
mkdir $LIBRARY/BAM_files
samtools sort $LIBRARY/top_hat/accepted_hits.bam $LIBRARY/BAM_files/accepted_hits_sorted.bam
samtools index $LIBRARY/BAM_files/accepted_hits_sorted.bam.bam

#First thing is generate the pileup format to proceed with SNP calling. Pileup format contains information of at individual chromosomal position level.
#mpileup -f indicates that the reference genome is in fasta format.
                
samtools mpileup -f $GENOME\.fasta $LIBRARY/BAM_files/accepted_hits_sorted.bam.bam | gzip -9 -c > $LIBRARY/accepted_hits_sorted.pileup.gz

#Next, it will proceed to SNP calling.
#The script with generate a file similar to BCF format, with Chr, ref position, reference base, sequenced base, frequency. 
                
mkdir $LIBRARY/SNPs
gunzip -c $LIBRARY/accepted_hits_sorted.pileup.gz | perl SCRIPTS/compsnps_pipe1_sampileup.py > $LIBRARY/SNPs/$LIBRARY\_SNP_ratios.txt
                
#Finally, the desired frequency of each SNP is calculated accordingly to the deep in sequencing. That is, it only takes into account SNP position with at least 20% of appearance (frequency) and 10 or 20 of deep coverage.
                
mkdir $LIBRARY/SNPs/10X
gunzip -c $LIBRARY/accepted_hits_sorted.pileup.gz | perl SCRIPTS/compsnps_pipe1_sampileup.py | perl SCRIPTS/compsnps_pipe_filter_SNPs_sample_stdin_pipe4_08.pl 10 0.2 0.8 > $LIBRARY/SNPs/10X/$LIBRARY\_SNP_freq_10x.txt
                
mkdir $LIBRARY/SNPs/20X
gunzip -c $LIBRARY/accepted_hits_sorted.pileup.gz | perl SCRIPTS/compsnps_pipe1_sampileup.py | perl SCRIPTS/compsnps_pipe_filter_SNPs_sample_stdin_pipe4_08.pl 20 0.2 0.8 > $LIBRARY/SNPs/20X/$LIBRARY\_SNP_freq_20x.txt    

#And verify the allele frequency
mkdir $LIBRARY/Allele_freq
perl $work/SCRIPTS/tab2ggplot2input_allele_frequency.pl $LIBRARY $LIBRARY/SNPs/20X/$LIBRARY\_SNP_freq_20x.txt $LIBRARY/Allele_freq/ 
