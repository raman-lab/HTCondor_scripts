#script to make submit files and shell scripts to run Rosetta ddg_monomer on Condor cluster
#pipe in list of mutfiles that will be used in ddg calc
#i.e. ls *.mutfile | <path_to_script>/ddg_submit_file_maker

#!/bin/bash

while read i
do
	fbname=${i%.mutfile}
	IFS='_' read -r -a arr <<< "$fbname"
	pdb=${arr[0]}_nolig_ddg.pdb
	
	cat <<-EOFsh > ${fbname}.sh
	#!/bin/bash

	tar -xzf database.tar.gz
	chmod a+x ddg_monomer.static.linuxgccrelease
	./ddg_monomer.static.linuxgccrelease -database ./database @ddg_flags -in:file:s ${pdb} -ddg::mut_file ${i} -ddg::iterations 50 > ddg_${i}_\${2}_\${1}.log

	mv ddg_predictions.out ddg_${i}_\${2}_\${1}.out
	rm mutant_traj* wt_traj
	rm -rf database/
	rm database.tar.gz
	rm ddg_monomer.static.linuxgccrelease
	EOFsh

	cat <<-EOFsub > ${fbname}.sub
	universe = vanilla
	log = CONDOR_${i}_\$(Cluster).log
	error = CONDOR_${i}_\$(Cluster)_\$(Process).err
	output = CONDOR_${i}_\$(Cluster)_\$(Process).out

	executable = ${fbname}.sh
	arguments = \$(Process) \$(Cluster)

	requirements = (OpSys == "LINUX")
	should_transfer_files = YES
	when_to_transfer_output = ON_EXIT

	# Leave the queue if job exits w/ 0 (normal exit code), else re-run job
	on_exit_remove = ExitCode =?= 0

	# Put on hold if job returns without specified ouput files and release
	periodic_release = (JobStatus == 5) && (HoldReasonCode == 13 || HoldReasonCode == 12)

	transfer_input_files = ${HOME}/TFs/ddg_flags, ${PWD}/../input.cst, ${i}, ${PWD}/../${pdb}, http://proxy.chtc.wisc.edu/SQUID/nwhoppe/database.tar.gz, http://proxy.chtc.wisc.edu/SQUID/nwhoppe/ddg_monomer.static.linuxgccrelease

	transfer_output_files = ddg_${i}_\$(Cluster)_\$(Process).log, ddg_${i}_\$(Cluster)_\$(Process).out
	
	request_cpus = 1
	request_memory = 2GB
	request_disk = 2GB
        
	+WantFlocking = true
	+WantGlidein = true
        
	queue 1
	EOFsub
done
