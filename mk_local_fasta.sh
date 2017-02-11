# script to make sub files, and sh files to run local Condor jobs to accelerate the process of making fastas from pdbs
# see options below for inputs - it is required to use all options but blocks

#!/bin/bash

path='.'
blocks=1

while [ "$1" != "" ]
do
        case "$1" in
                -l | --ligand)
                        shift
                        lig="$1";;
                -a | --alignment_int)
                        shift
                        a_int="$1";;
		-p | --pair_int)
			shift
			p_int="$1";;
		-d | --directory)
			shift
			path="$1";;
		-b | --block_int)
			shift
			blocks="$1";;
                * )
                        echo "Invalid Argument"
			echo
			echo "Valid arguments are:"
			echo "-l | --ligand <name of ligand as it appears in input and output files> required"
			echo "-a | --alignment_int <number of alignments (zero indexed)> required"
			echo "-p | --pair_int <number of pairings (zero indexed)> required"
			echo "-d | --directory <path to output pdbs> default is '.'"
			echo "-b | --block_int <number of blocks (zero indexed)> default is 1" 
                        exit;;
        esac
        shift
done


for ((a=0; a<=${a_int}; a++))
do
	for ((p=0; p<=${p_int}; p++))
	do
		for ((b=0; b<=${blocks}; b++))
		do
			cat <<-EOFsh > local_fasta_${lig}_A${a}_P${p}_B${b}.sh
			#!/bin/bash
			find ${path} -name '*${lig}_A${a}_P${p}*B${b}*.pdb' | xargs ~/scripts/fas_from_pdb_stdout.py > ${lig}_A${a}_P${p}_B${b}.fasta
			EOFsh

			cat <<-EOFsub > local_fasta_${lig}_A${a}_P${p}_B${b}.sub
			universe = local
			log = CONDOR_local_fasta_${lig}_A${a}_P${p}_B${b}.log
			error = CONDOR_local_fasta_${lig}_A${a}_P${p}_B${b}.err
			output = CONDOR_local_fasta_${lig}_A${a}_P${p}_B${b}.out
			
			# Leave the queue if job exits w/ 0 (normal exit code), else re-run job
			on_exit_remove = ExitCode =?= 0
	
			executable = local_fasta_${lig}_A${a}_P${p}_B${b}.sh

			queue 1
			EOFsub
		done
	done
done
