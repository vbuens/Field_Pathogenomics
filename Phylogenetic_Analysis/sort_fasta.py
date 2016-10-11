from Bio import SeqIO
import argparse

parser = argparse.ArgumentParser(description="Sort fasta files by label.")
parser.add_argument("--fasta", "-f")

args = parser.parse_args()

handle = open(args.fasta, "rU")
l = SeqIO.parse(handle, "fasta")
sortedList = [f for f in sorted(l, key=lambda x : x.id)]
for s in sortedList:
   print s.description
   print str(s.seq)

