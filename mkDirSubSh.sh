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

		# Design for ligand binding using ${protocol} protocol
		tar -xzf database.tar.gz
		chmod +x rosetta_scripts.static.linuxgccrelease
		./rosetta_scripts.static.linuxgccrelease -database ./database -parser::protocol ${protocol}.xml -in::file::s $i -extra_res_fa LG.params @${protocol}_flags -parser::script_vars ligchain=X resfile=${pdb}_${k}.resfile -packing::unboundrot $i -seed_offset \$1 -out:suffix _${k}_\$2_\$1 -out:file:o ${fbname}_${k}_\${2}_\${1}.pdb -scorefile score_${fbname}_${k}_\${2}_\${1}.sc -nstruct ${nstructN} > RUN_${fbname}_${k}_\${2}_\${1}.log

		# Revert design to native based on ddg
		chmod +x revert_design_to_native.static.linuxgccrelease
		shopt -s nullglob
		for fname in ${fbname}_${k}_*.pdb
		do
			./revert_design_to_native.static.linuxgccrelease -database ./database -extra_res_fa LG.params -score:weights enzdes -ex1 -ex2 -revert_app:ddg_cycles 1 -revert_app:wt $i -revert_app:design \${fname} >> REVERT_${fbname}_${k}_\${2}_\${1}.log
		done

		# Rescore reverted designs
		ls *.revert.pdb > infile
		./rosetta_scripts.static.linuxgccrelease -database ./database @enzscore_flags -parser::protocol enzscore_1.xml -in::file::fullatom -extra_res_fa LG.params -out::file::scorefile rescore_${fbname}_${k}_\${2}_\${1}.sc -in:file:l infile > RESCORE_${fbname}_${k}_\${2}_\${1}.log

		# Remove unneeded files
		find . -type f -name '*.pdb' ! -name '*.revert_0001.pdb' -exec rm {} \;
		rm infile
		rm -rf database/
		EOFsh

		cat <<-EOFsub > ${path}/${fbname}_${k}.sub
		universe = vanilla
		log = CONDOR_${fbname}_${k}_\$(Cluster).log
		error = CONDOR_${fbname}_${k}_\$(Cluster)_\$(Process).err
		output = CONDOR_${fbname}_${k}_\$(Cluster)_\$(Process).out
			
		executable = ${fbname}_${k}.sh
		arguments = \$(Process) \$(Cluster)

		requirements = (OpSys == "LINUX")
		should_transfer_files = YES
		when_to_transfer_output = ON_EXIT

		# Leave the queue if job exits w/ 0 (normal exit code), else re-run job
		on_exit_remove = ExitCode =?= 0

		# Put on hold if job returns without specified ouput files and release
		periodic_release = (JobStatus == 5) && (HoldReasonCode == 13 || HoldReasonCode == 12)

		initialdir = ${path}/output
		transfer_input_files = ${path}/$i, ${homeDirVar}/TFs/${protocol}.xml, ${homeDirVar}/TFs/${protocol}_flags, ${homeDirVar}/TFs/hack_elec.wts_patch, ${path}/LG.params, ${homeDirVar}/TFs/${pdb}_${k}.resfile, ${homeDirVar}/TFs/enzscore_flags, ${homeDirVar}/TFs/enzscore_1.xml, http://proxy.chtc.wisc.edu/SQUID/nwhoppe/database.tar.gz, http://proxy.chtc.wisc.edu/SQUID/nwhoppe/rosetta_scripts.static.linuxgccrelease, http://proxy.chtc.wisc.edu/SQUID/nwhoppe/revert_design_to_native.static.linuxgccrelease 

		transfer_output_files = ${fbname}_${k}_\$(Cluster)_\$(Process)_0001.pdb.revert_0001.pdb, ${fbname}_${k}_\$(Cluster)_\$(Process)_0002.pdb.revert_0001.pdb, ${fbname}_${k}_\$(Cluster)_\$(Process)_0003.pdb.revert_0001.pdb, ${fbname}_${k}_\$(Cluster)_\$(Process)_0004.pdb.revert_0001.pdb, ${fbname}_${k}_\$(Cluster)_\$(Process)_0005.pdb.revert_0001.pdb, ${fbname}_${k}_\$(Cluster)_\$(Process)_0006.pdb.revert_0001.pdb, ${fbname}_${k}_\$(Cluster)_\$(Process)_0007.pdb.revert_0001.pdb, ${fbname}_${k}_\$(Cluster)_\$(Process)_0008.pdb.revert_0001.pdb, ${fbname}_${k}_\$(Cluster)_\$(Process)_0009.pdb.revert_0001.pdb, ${fbname}_${k}_\$(Cluster)_\$(Process)_0010.pdb.revert_0001.pdb, RESCORE_${fbname}_${k}_\$(Cluster)_\$(Process).log, REVERT_${fbname}_${k}_\$(Cluster)_\$(Process).log, RUN_${fbname}_${k}_\$(Cluster)_\$(Process).log, rescore_${fbname}_${k}_\$(Cluster)_\$(Process).sc, score_${fbname}_${k}_\$(Cluster)_\$(Process).sc

		request_cpus = 1
		request_memory = 3GB
		request_disk = 3GB

		+WantFlocking = true
		+WantGlidein = true

		queue ${queueN}
		EOFsub
	done
done
