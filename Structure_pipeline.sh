#Usage: bash Structure_pipeline.sh -l libraries_for_structure.txt -i SNPEFF_dir -d Structure/

source perl-5.20.1;
source bioperl-1.6.922; 


#Default output directories:
SYNDATA_DIR="Syn_all_data"
SYNONYMOUS_DIR="Synonymous"
SNPEFF_DIR="SNPEFF"
WORKING_DIR="Structure"

while [[ $# -gt 1 ]]
do
	key="$1"

	case $key in
		-l|--ListofLibraries)
		LIST_FILE="$2"
		shift
    	;;
    	-i|--inputDir)
		SNPEFF_DIR="$2"
		shift
		;;
		-d|--WorkingDirectory)
		WORKING_DIR="$2"
		shift
		;;
    	*) echo "Usage: Structure_pipeline.sh -l libraries_for_structure.txt -i SNPEFF_dir -d Structure/. Unkown option: $1 " >&2 ; exit 1
		;;
  	esac
  	shift
done

if [ -z $LIST_FILE ]; then	echo "No list of libraries given! Usage: Structure_pipeline.sh -l libraries_for_structure.txt -d Structure/ -i SnpEff_directory"; exit 1 ; fi
if [ -z $SNPEFF_DIR ]; then	echo "No SnpEff files directory given! Using 'SNPEFF' by default... ";  fi
if [ -z $WORKING_DIR ]; then	echo "No SnpEff files directory given! Using 'Structure' by default..."; fi


if [ ! -d $WORKING_DIR/$SYNONYMOUS_DIR/Filtered ]; then mkdir -p $WORKING_DIR/$SYNONYMOUS_DIR/Filtered ;fi
if [ ! -d $WORKING_DIR/$SYNDATA_DIR ]; then mkdir $WORKING_DIR/$SYNDATA_DIR ;fi
if [ ! -d $WORKING_DIR/$STR ]; then mkdir $WORKING_DIR/$STR ;fi


while read line; do

	#Extract synonymous sites only. If you want to work with non-synonymous or all sites, change the following script (SNPs_extract_snpEff_syn_coding.pl)
	if [ -f $SNPEFF_DIR/$line\_snpEff.txt ]
	then
		perl SCRIPTS/Population_STRUCTURE/snpeff_and_structure/SNPs_extract_snpEff_syn_coding.pl $SNPEFF_DIR/$line\_snpEff.txt > $WORKING_DIR/$SYNONYMOUS_DIR/$line\_snpEff_syn_snps.txt
		echo $line  " - SNPs extracted"
	else
		echo $line " SnpEff file could not be found"
	fi

	if [ -f $WORKING_DIR/$SYNONYMOUS_DIR/$line\_snpEff_syn_snps.txt ]
	then
		#Extract synonymous sites that have at least 20x coverage
 		perl SCRIPTS/Population_STRUCTURE/snpeff_and_structure/compare_snpeff_filtered_to_galaxy20.pl $WORKING_DIR/$SYNONYMOUS_DIR/$line\_snpEff_syn_snps.txt $line/SNPs/20X/$line\_SNP_freq_20x.txt > $WORKING_DIR/$SYNONYMOUS_DIR/Filtered/$line\_snpeff_syn_snps_filt.txt
 		echo $line " done!"
 	else
 		echo $line " filtered file could not be created. Input file not found."
 	fi

done < $LIST_FILE # Example : libraries_structure.txt (Text file with the name of the libraries)


# Generate 'positions' file

perl SCRIPTS/Population_STRUCTURE/snpeff_and_structure/generate_position_info_from_files_mod.pl Positions.txt $WORKING_DIR $SYNONYMOUS_DIR

mv Positions.txt $WORKING_DIR/$SYNONYMOUS_DIR/Filtered/


# Generate the files for each sample	
while read line; do

# 	# Create a directory for each sample
	if [ ! -d $WORKING_DIR/$SYNDATA_DIR/$line ]; then mkdir $WORKING_DIR/$SYNDATA_DIR/$line ; fi
 
# 	#Copy positions file to each directory created above
 	cp $WORKING_DIR/$SYNONYMOUS_DIR/Filtered/Positions.txt $WORKING_DIR/$SYNDATA_DIR/$line/

	if [ ! -d References2X ]; then
 		echo "References2x directory not found. Creating one..."
 		mkdir References2X

 		if [ ! -f References2X/$line\_Reference_greater_2x.tab ];  then
 			echo $line "- Reference2x file not found! Creating file..."
	 		perl SCRIPTS/Population_STRUCTURE/extract_2x_same_ref.pl $line/SNPs/$line\_SNP_ratios.txt > References2X/$line\_Reference_greater_2x.tab

 		fi

	 fi

#    	#Generate the file that contains the positions that are equal to the reference by 2X, or different by 20X
	perl SCRIPTS/Population_STRUCTURE/snpeff_and_structure/combine_snps_filtered_reference3x.pl References2X/$line\_Reference_greater_2x.tab $WORKING_DIR/$SYNONYMOUS_DIR/Filtered/$line\_snpeff_syn_snps_filt.txt >  $WORKING_DIR/$SYNDATA_DIR/$line/$line\_syn_all_data.txt
	echo $line " - Step 1"
# #    	#Generate structure input
# # 	# You need to change the number in $filename[NUMBER] in the following script beforw running it, counting the number of "steps" in the path
	perl SCRIPTS/Population_STRUCTURE/snpeff_and_structure/generate_Structure_input.pl  $WORKING_DIR/$SYNDATA_DIR/$line/Positions.txt  $WORKING_DIR/$SYNDATA_DIR/$line/$line\_Structure_syn_data2.str $line $SYNDATA_DIR $WORKING_DIR

  	echo $line " done!"

done < $LIST_FILE # Example : libs_for_structure.txt (Text file with the name of the libraries)

#Create a directory to save the final structure input file, if it hasn't been created yet.


if [ ! -d  $WORKING_DIR/Structure_input ];
then 
	mkdir  $WORKING_DIR/Structure_input
fi
  	
# #Cat all the above individual input files
cat  $WORKING_DIR/$SYNDATA_DIR/LIB*/*_Structure_syn_data2.str >  $WORKING_DIR/Structure_input/Structure_syn_all_data_same_allele.str
#Add the number to the allele (1,2 for biallelic) to the sample names
perl SCRIPTS/Population_STRUCTURE/snpeff_and_structure/Add_allele_number_Structure_input.pl  $WORKING_DIR/Structure_input/Structure_syn_all_data_same_allele.str  $WORKING_DIR/Structure_input/Structure_syn_all_data.str

#Now we will modify the format of the STRUCTURE input file.

perl SCRIPTS/Population_STRUCTURE/snpeff_and_structure/transpose_matrix_space_delimited.pl  $WORKING_DIR/Structure_input/Structure_syn_all_data.str >  $WORKING_DIR/Structure_input/Structure_syn_all_data_flip.str 

perl SCRIPTS/Population_STRUCTURE/snpeff_and_structure/remove_multiallelic.pl  $WORKING_DIR/Structure_input/Structure_syn_all_data_flip.str  $WORKING_DIR/Structure_input/Structure_syn_all_data_biallelic.txt

perl SCRIPTS/Population_STRUCTURE/snpeff_and_structure/transpose_matrix_space_delimited.pl  $WORKING_DIR/Structure_input/Structure_syn_all_data_biallelic.txt >  $WORKING_DIR/Structure_input/Structure_syn_all_data_biallelic_flip.str

