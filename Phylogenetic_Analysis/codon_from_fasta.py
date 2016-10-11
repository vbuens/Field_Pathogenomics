from __future__ import print_function
import os
import sys
import glob
import argparse
import pprint

# Courtesy of http://stackoverflow.com/questions/5574702/how-to-print-to-stderr-in-python
def eprint(*args, **kwargs):
        print(*args, file=sys.stderr, **kwargs)

# Courtesy from http://omar.toomuchcookies.net/node/2012/01/pythonic-way-of-opening-more-than-one-file-at-a-time/
# The idea is to open all the files at the same time but only read them line by line
# This function returns all the file handlers for the duration of the "with" operation
class openFiles():
    def __init__(self, files, flags):
        if isinstance(files,basestring):
            files = [files]
        if isinstance(flags,basestring):
            flags = [flags]
        assert len(flags)==len(files)
        self.files = files
        self.flags = flags
    def __enter__(self):
        self.fhs = []
        for f, fl in zip(self.files, self.flags):
            self.fhs.append(open(f,fl))
        return self.fhs

    def __exit__(self, type, value, traceback):
        for f in self.fhs:
            f.close()

# Prettifying the command line argument parser
def check_range(arg):
    try:
        value = int(arg)
    except ValueError as err:
       raise argparse.ArgumentTypeError(str(err))
    if value < 0 or value > 100:
        message = "Expected 0 <= value <= 100, got value = {}".format(value)
        raise argparse.ArgumentTypeError(message)
    return value

# Command-line parser enhancements from
# https://gist.github.com/brantfaircloth/1443543
class FullPaths(argparse.Action):
    """Expand user- and relative-paths"""
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, os.path.abspath(os.path.expanduser(values)))

def is_dir(dirname):
    """Checks if a path is an actual directory"""
    if not os.path.isdir(dirname):
        msg = "{0} is not a directory".format(dirname)
        raise argparse.ArgumentTypeError(msg)
    else:
        return dirname


# Read from the files with markers lower or equal to the current marker
def read_markers(files, current_marker, markers):
    have_seqs = False
    for counter, file in enumerate(files):
        if (current_marker != markers[counter]["ID"] and current_marker != ""):
            markers[counter]["seq"] = ""
        else:
            markers[counter]["ID"] = file.readline().replace('\r','').replace('\n', '')
            markers[counter]["seq"] = file.readline().replace('\r','').replace('\n', '')
            if (markers[counter]["seq"] != ""):
                have_seqs = True
    return have_seqs, markers


parser = argparse.ArgumentParser(description="Output the chosen codons (1, 2, 3, 1&2) for all the genes with a defined percentage of coverage in the fasta samples (ordered by gene) on a particular directory.")
parser.add_argument("--directory", "-d", required=True, action=FullPaths, type=is_dir, help="Directory containing the sorted fasta samples")
parser.add_argument("--codon", "-c", choices=['codon1', 'codon2', 'codon3', 'codon12', 'codon123'], default='codon3')
parser.add_argument("--min-sequence", "-s", type=check_range, nargs="?", metavar="0-100", help="Minimum percentage of sequence required to be known on a sample to mark as valid",default=0)
parser.add_argument("--min-samples", "-l", type=check_range, nargs="?", metavar="0-100", help="Minium percentage of accepted libraries to include a gene in the final sequence", default=0)
args = parser.parse_args()

codon_option = args.codon
workdir = args.directory
min_sequence = float(args.min_sequence)/100.0
min_samples = float(args.min_samples)/100.0

opened_files = sorted(glob.glob(workdir+"/*.sorted"))
filtered_files = [s + ".filtered" for s in opened_files]
# current_marker keeps the marker we are interested in (minimum read marker from all the files)
current_marker = ""

# markers will keep a list of the current markers, represented as a dictionary with ID and val containing the sequence
markers = []
for i, f in enumerate(opened_files):
    markers.insert(i, {"ID":"", "seq":""})

# This is a test that shows how choosing the current marker works
#markers = [
#        {'ID':8,'seq':"AAAA"},
#        {'ID':8,'seq':"AAAC"},
#        {'ID':9,'seq':"ASD"},
#        {'ID':10,'seq':"AWRE"},
#        {'ID':11,'seq':"ASDG"},
#        ]
genes_rejected = []
genes_accepted = []
num_genes = 0
# Open a variable list of files from a directory in write mode (filtered files)
with openFiles(filtered_files, ['w' for x in range(len(filtered_files))]) as ww:
# Open a variable list of files from a directory in read mode (sorted files)
    with openFiles(opened_files, ['r' for x in range(len(opened_files))]) as ll:
        have_seqs, markers = read_markers(ll, current_marker, markers) # Read the markers from the files and check if we still have markers to read, the _first time it asumes no file is empty_
        current_marker = min([x["ID"] for x in markers if x["ID"] != ""])
        while have_seqs:
            num_genes += 1
            has_enough_coverage = [True] * len(opened_files)
            max_length = max([len(x["seq"]) for x in markers if x["ID"] == current_marker])
            print("Gene", current_marker, "has a max length of", max_length)
            num_samples_low_coverage = 0
            for i, m in enumerate(markers):
                if (m["ID"] != current_marker):
                    num_samples_low_coverage+=1
                    has_enough_coverage[i] = False
                    print("File ", os.path.basename(opened_files[i]), " doesn't contain gene ", current_marker)
                    continue
                # eprint("File ", opened_files[i], " contains gene ", current_marker)
                if (len(m["seq"]) > 0):
                    info_percentage = 1.0 - m["seq"].count("N") / float(max_length)
                else:
                    info_percentage = 0.0
                if info_percentage <= min_sequence: # Are all my samples complete? or at least with N percentage of information?
                    print("Sample", os.path.basename(opened_files[i]), "only has", str(round(100.0*info_percentage,2)), "% coverage for", m["ID"])
                    num_samples_low_coverage+=1
                    has_enough_coverage[i] = False
            # Check that this gene has enough information on at least N percent of the samples print it to the filtered output
            if (min_samples <= has_enough_coverage.count(True)/float(len(has_enough_coverage))):
                eprint("Gene", current_marker, "accepted")
                genes_accepted.append(current_marker)
                longest_seq = max([len(x["seq"]) for x in markers if x["ID"] == current_marker])
                for file, m in enumerate(markers):
                    if m["ID"] == current_marker:
                        # eprint("LIB ", opened_files[file], " contains gene ", current_marker)
                        m["seq"] = m["seq"].ljust(longest_seq, "N") # Pad the genes with ? for the lenght of unknowns
                        printed = 0
                        for i, c in enumerate(m["seq"]):
                            if ( i%3 == 0 and (codon_option == 'codon1' or codon_option == 'codon12' or codon_option == 'codon123') ):
                                ww[file].write(c)
                                printed+=1
                            if ( i%3 == 1 and (codon_option == 'codon2' or codon_option == 'codon12' or codon_option == 'codon123') ):
                                ww[file].write(c)
                                printed+=1
                            if ( i%3 == 2 and (codon_option == 'codon3' or codon_option == 'codon123' )):
                                ww[file].write(c)
                                printed+=1
                    else:
                        # eprint("LIB ", opened_files[file], " doesn't contain gene ", current_marker)
                        if (codon_option == 'codon1' or codon_option == 'codon2' or codon_option == 'codon3'):
                            ww[file].write("N" * (longest_seq/3))
                        elif (codon_option == 'codon12'):
                            ww[file].write("N" * (longest_seq*2)/3)
                        else:
                            ww[file].write("N" * longest_seq)
            else:
                eprint("Rejected: Gene", current_marker, "it has low coverage for", num_samples_low_coverage, "samples, out of", len(has_enough_coverage), "samples. Representing:", str(round(100 * has_enough_coverage.count(True)/float(len(has_enough_coverage)),2)), "% of the samples")
                genes_rejected.append(current_marker)

            have_seqs, markers = read_markers(ll, current_marker, markers)
            if have_seqs:
                current_marker = min([x["ID"] for x in markers if (x["seq"] != "" and x["ID"] != "")]) # Since the file might have reached EOF we do not consider files that are not advancing nor genes that do not exist (ID == "")

print()
print("Summary")
print("From", len(opened_files), "libraries, with a total of", num_genes, "genes,", len(genes_accepted), "genes were accepted and", len(genes_rejected), "genes were rejected.")
print("The following genes were accepted:")
print(genes_accepted)

print("The following genes were rejected:")
print(genes_rejected)


sys.exit()


