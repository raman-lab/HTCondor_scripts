#!/bin/bash

# for use in submit.biochem.wisc.edu scratch folders
struct="4AC0"
lig="Resv"
echo "Structure: $struct, Ligand: $lig"
echo "Number of blocks (B):"
read blocks
echo "Number of alignments (A):"
read alignments
echo "Number of positions (P):"
read positions
#echo "Number of conformers (C):"
#read conformers


mkdir -p ~/fasta_files/${struct}/${lig}
for b in $(seq 0 $blocks)
do
	for a in $(seq 0 $alignments)
	do
		for p in $(seq 0 $positions)
		do
			for file in ${struct}_${lig}_A${a}_P${p}_C*B${b}*.pdb
			do
				/scratch/sraman4/src/pdbUtil/getFastaFromCoords.pl -PDB $file >> ~/fasta_files/${struct}/${lig}/${struct}_${lig}_A${a}_P${p}_enzdes_B${b}.fasta
				echo "$file"
			done
		done
	done
done
