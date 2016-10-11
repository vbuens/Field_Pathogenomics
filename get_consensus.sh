#Usage: get_consensus.sh -g Genome_folder/Genome.gff3 -o output_directory -l libraries.txt


OUTPUT_DIR="consensus"

while [[ $# -gt 1 ]]
do
	key=$1
	case $key in
		-g|--genome) #Give the directory where the reference genome in GFF3 format is.
		GENOME="$2"
		shift
		;;
		-o|--output)
		OUTPUT_DIR="$2"	#Output directory
		shift
		;;
		-l|--ListofLibraries)
		LIST_FILE="$2"
		shift
		;;
		*) echo "Usage: get_consensus.sh -g Genome_folder/Genome.gff3 -o output_directory -l libraries.txt. Unkown option: $1 " >&2 ; exit 1
		;;
	esac
	shift
done

if [ -z $GENOME ]; then	echo "No Genome in gff3 format given! Usage: get_consensus.sh -g Genome_folder/Genome.gff3 -o output_folder -l libraries.txt"; exit 1 ; fi
if [ -z $LIST_FILE ]; then	echo "No list of libraries given! Usage: get_consensus.sh -g Genome_folder/Genome.gff3 -o output_folder -l libraries.txt"; exit 1 ; fi

echo GENOME = "${GENOME}"
echo OUTPUT_DIR = "${OUTPUT_DIR}"


#Create output directories

if [ ! -d References2X ] ; then
	mkdir References2X
fi

if [ ! -d $OUTPUT_DIR ] ; then
	mkdir $OUTPUT_DIR
fi


while read line; do

 	if  [ ! -f References2X/$line\_Reference_greater_2x.tab ]; then
 		#Create output file with all positions similar to the Reference Genome with at least 2x coverage
		perl SCRIPTS/Phylogenetic_Analysis/extract_2x_same_ref.pl $line/SNPs/$line\_SNP_ratios.txt > References2X/$line\_Reference_greater_2x.tab
 	fi


 	if  [ ! -f $OUTPUT_DIR/$line\_20x_$consensus_cds.fa ]; then
 		#Create consensus files using the Reference Genome in GFF3 format
		perl SCRIPTS/Phylogenetic_Analysis/get_consensus.pl -p $line\_20x -o $OUTPUT_DIR -a References2X/$line\_Reference_greater_2x.tab -s $line/SNPs/20X/$line\_SNP_freq_20x.txt -gf $GENOME

 	fi
		echo $line " is done!"

done < $LIST_FILE #Text file with the name of the libraries


