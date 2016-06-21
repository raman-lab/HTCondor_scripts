# script to make directories, sub files, and sh files to run Condor jobs for a set of pdbs, protocols, and resfiles
# takes ls -1 <list of pdb files> as piped input
# i.e. ls -1 *.pdb | ~/Scripts/mkDirSubSh.sh
# protocols and resfiles are hard coded

#!/bin/bash

queueN=1000
nstructN=10
protocol='enzdes'
blocks='B0 B1'

while [ "$1" != "" ]
do
        case "$1" in
                -q | --queue)
                        shift
                        queueN="$1";;
                -n | --nstruct)
                        shift
                        nstructN="$1";;
		-p | --protocol)
			shift
			protocol="$1";;
		-b | --block)
			shift
			blocks="$1";;
                * )
                        echo "Invalid Argument"
			echo
			echo "Valid arguments are:"
			echo "-q | --queue <number of jobs to queue per sub file> default is 1000"
			echo "-n | --nustruct <number of structures per sh file> default is 10"
			echo "-p | --p protocol <'name of protocol'> defualt is 'enzdes'"
			echo "-b | --block <'space separated list of amino acid blocks'> default is 'B0 B1'" 
                        exit;;
        esac
        shift
done


while read i
do
        fbname=${i%.*}
	IFS='_' read -r -a arr <<< "$fbname"
	pdb=${arr[0]}
	lig=${arr[1]}
	ali=${arr[2]}
	pair=${arr[3]}
	conf=${arr[4]}
	for k in ${blocks}
	do
		mkdir -p ~/$pdb/$lig/output
		path=~/$pdb/$lig
		homeDirVar=~
		cat <<-EOFsh > ${path}/${fbname}_${k}.sh
		#!/bin/bash

		wget http://proxy.chtc.wisc.edu/SQUID/nwhoppe/database.tar.gz
		tar -xzvf database.tar.gz
		wget http://proxy.chtc.wisc.edu/SQUID/nwhoppe/rosetta_scripts.linuxgccrelease

		chmod a+x rosetta_scripts.linuxgccrelease
		./rosetta_scripts.linuxgccrelease -database ./database -parser::protocol ${protocol}.xml -in::file::s $i -extra_res_fa LG.params @${protocol}_flags -parser::script_vars ligchain=X resfile=${pdb}_${k}.resfile -packing::unboundrot $i -seed_offset \$1 -out:suffix _${k}_\$2_\$1 -out:file:o ${fbname}_${k}_\${2}_\${1}.pdb -scorefile score_${fbname}_${k}_\${2}_\${1}.sc -nstruct ${nstructN} > RUN_${fbname}_${k}_\${2}_\${1}.log

		rm -rf database/
		rm database.tar.gz
		rm rosetta_scripts.linuxgccrelease
		EOFsh

		cat <<-EOFsub > ${path}/${fbname}_${k}.sub
		universe = vanilla
		log = CONDOR_${fbname}_${k}_\$(Cluster).log
		#error = CONDOR_${fbname}_${k}_\$(Cluster)_\$(Process).err
		#output = CONDOR_${fbname}_${k}_\$(Cluster)_\$(Process).out
			
		executable = ${fbname}_${k}.sh
		arguments = \$(Process) \$(Cluster)

		should_transfer_files = YES
		when_to_transfer_output = ON_EXIT

		# Leave the queue if job exits w/ 0 (normal exit code), else re-run job
		on_exit_remove = ExitCode =?= 0

		# Put the job on hold if it tried too often
		on_exit_hold = JobRunCount > 5

		initialdir = ${path}/output
		transfer_input_files = ${path}/$i, ${homeDirVar}/TFs/${protocol}.xml, ${homeDirVar}/TFs/${protocol}_flags, ${homeDirVar}/TFs/hack_elec.wts_patch, ${path}/LG.params, ${homeDirVar}/TFs/rah_${protocol}.xml, ${homeDirVar}/TFs/${pdb}_${k}.resfile

		request_cpus = 1
		request_memory = 2GB
		request_disk = 2GB

		+WantFlocking = true
		+WantGlidein = true

		queue ${queueN}
		EOFsub
	done
done
