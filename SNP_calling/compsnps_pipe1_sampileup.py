#!/usr/bin/env python
#encoding: utf-8
"""
Converts a pileup into the SNP_ratios format, with tab separated columns
CHROM, POS, REF, DEPTH, OBSERVED, SNP RATIO

OBSERVED and SNP RATIO are ordered together and are comma separated.
"""
import sys
import re
from collections import Counter

def process_pileup_line(line):
    '''Summarise a single line (site) in pileup format'''
    chr, position, ref, depth, base, quality = line.split("\t")
    
    # Discard strand information
    base = base.upper()
    base = base.replace(',', '.')
    
    base_counts = Counter(list(base))
    ## Remove INDELs
    for m in re.finditer('([+|-])(\d+)(\w+)', base):
        indel_length = int(m.group(2))
        indel_bases = (m.group(3))[0:indel_length]
        indel_counts = Counter(list(indel_bases))
        base_counts = Counter({b:base_counts[b] - indel_counts[b] for b in base_counts.keys() })
        
    base_counts[ref]+=base_counts['.']
    base_counts['.'] = 0
    
    ## Calculate allele ratios
    nucleotides = ['A', 'T', 'C', 'G']
    ratios = {}
    for n in nucleotides:
        if base_counts[n] > 0:
            ratios[n] = str(round(base_counts[n]/float(depth), 3))
    
    return [chr, position, ref, depth, ",".join(ratios.keys()), ",".join(ratios.values())]
    
    
for pileup_line in sys.stdin: 
    pileup_line = pileup_line.rstrip() #remove new line mark
    print "\t".join(process_pileup_line(pileup_line))
        
        
        
            
            
            
