# Usage: bash create_snpeffs.sh -l libraries_for_structure.txt -g Genome.gff3 -n species

source bedtools-2.17.0;
source jre-7.11;


#Default values:
NAME_SPECIES="PST-130"

while [[ $# -gt 1 ]]
do
	key="$1"

	case $key in
		-l|--ListofLibraries)
		LIST_FILE="$2"
		shift
    	;;
    	-g|--GFFgenome)
		GFF_GENOME="$2"
		shift
		;;
		-n|--NameOfSpecies)
		NAME_SPECIES="$2"
		shift
		;;
    	*) echo "Usage: create_snpeffs.sh -l libraries_for_structure.txt -g Genome.gff3 -n PST-130. Unkown option: $1 " >&2 ; exit 1
		;;
  	esac
  	shift
done

if [ -z $LIST_FILE ]; then	echo "No list of libraries given! Usage: create_snpeffs.sh -l libraries_for_structure.txt -g Genome.gff3 -n PST-130"; exit 1 ; fi
if [ -z $GFF_GENOME ]; then echo "No gff3 file given! Usage: create_snpeffs.sh -l libraries_for_structure.txt -g Genome.gff3 -n PST-130 " ; exit 1; fi 	; GFF_GENOME=$1
if [ -z $NAME_SPECIES ]; then echo "No name of species given! Using PST-130 by default..." ; fi 


while read line; do

	#Convert 20x SNPs file to BED format

	bedtools intersect -a $line/SNPs/20X/$line\_SNP_freq_20x.txt -b $GFF_GENOME -wb > $line/SNPs/$line\_comsnps_outfile.out 

	if [ -f $line/SNPs/$line\_comsnps_outfile.out ]
	then
 		echo $line “- First step is finished”
	#Convert to snpEff input format
		perl SCRIPTS/Population_STRUCTURE/snpEff/associated_scripts/snppipeout2snpeff_mod.pl $line/SNPs/$line\_comsnps_outfile.out > $line/SNPs/snpeff_input_$line\_comsnps_outfile.txt
	fi

	if [ -f $line/SNPs/snpeff_input_$line\_comsnps_outfile.txt ]
	then
		echo $line “-Second step is finished”
		
		#RUN SNPEFF locally in the snpEff folder. Change the following command if you change the folder where the scripts are:
		cd SCRIPTS/Population_STRUCTURE/snpEff #cd path/to/snpEff.jar

		java -Xmx4G -jar snpEff.jar eff -i txt $NAME_SPECIES $line/SNPs/snpeff_input_$line\_comsnps_outfile.txt -o txt > $line/SNPs/$line\_snpEff.txt

	fi
	
	cd ../../
done < $LIST_FILE	#file with the name of the libraries that you want to create the files


