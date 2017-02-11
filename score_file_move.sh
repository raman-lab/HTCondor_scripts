#!/bin/bash

# for use in submit.biochem.wisc.edu scratch/<name>/<struct>/<lig>/ output folders
struct="4AC0"
lig="Chrys"
echo "Structure: $struct, Ligand: $lig"
echo "Number of blocks (B):"
read blocks
echo "Number of alignments (A):"
read alignments
echo "Number of positions (P):"
read positions

mkdir /scratch/knishikawa/score_files/${lig}
for b in $(seq 0 $blocks)
do
	for a in $(seq 0 $alignments)
	do
		for p in $(seq 0 $positions)
			do
				
				echo "Making directory for ${struct}_${lig}_B${b}_A${a}_P${p}"
				mkdir /scratch/knishikawa/score_files/${lig}/${struct}_${lig}_B${b}_A${a}_P${p}
				touch /scratch/knishikawa/score_files/${lig}/${struct}_${lig}_B${b}_A${a}_P${p}/all_score_${struct}_${lig}_B${b}_A${a}_P${p}.txt
				touch /scratch/knishikawa/score_files/${lig}/best_ligscores.txt
				touch /scratch/knishikawa/score_files/${lig}/worst_ligscores.txt
				echo "Moving score files..."
				cp score*${struct}*${lig}*B${b}_A${a}_P${p}*.sc /scratch/knishikawa/score_files/${lig}/${struct}_${lig}_B${b}_A${a}_P${p}
				echo "Analyzing... ${struct}_${lig}_B${b}_A${a}_P${p}"
				for file in score*${struct}*${lig}*B${b}_A${a}_P${p}*.sc
				do
					cat $file | tail -10 >> /scratch/knishikawa/score_files/${lig}/${struct}_${lig}_B${b}_A${a}_P${p}/all_score_${struct}_${lig}_B${b}_A${a}_P${p}.txt
				done
				cat /scratch/knishikawa/score_files/${lig}/${struct}_${lig}_B${b}_A${a}_P${p}/all_score_${struct}_${lig}_B${b}_A${a}_P${p}.txt | sort -k16,1 -n -k1,2 | head -10 >> /scratch/knishikawa/score_files/${lig}/best_ligscores.txt
				cat /scratch/knishikawa/score_files/${lig}/${struct}_${lig}_B${b}_A${a}_P${p}/all_score_${struct}_${lig}_B${b}_A${a}_P${p}.txt | sort -k16,1nr -n -k1,2 | head -10 >> /scratch/knishikawa/score_files/${lig}/worst_ligscores.txt
			done
	done
done
