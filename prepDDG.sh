# script to make the directories and files for ddg_monomer calculations
# change variables at top as needed

#!/bin/bash
sequence=$(cat $2)
aaCount=${#sequence}
pdb=$1
fbname=${1%.*}
aaS="ARNDCQEGHILKMFPSTWYV"
for (( i=1; i<$aaCount; i++))
do
	aaRMd="${aaS//${sequence:$i:1}}" 
	mkdir -p /scratch/mleander/ddg/$fbname/$i
        path=/scratch/mleander/ddg/$fbname
        cat <<-EOFmut > ${path}/$i/${fbname}_${i}.mutfile
	total 19
	1
	${sequence:$i:1} $i ${aaRMd:0:1}
	1
	${sequence:$i:1} $i ${aaRMd:1:1}
	1
	${sequence:$i:1} $i ${aaRMd:2:1}
	1
	${sequence:$i:1} $i ${aaRMd:3:1}
	1
	${sequence:$i:1} $i ${aaRMd:4:1}
	1
	${sequence:$i:1} $i ${aaRMd:5:1}
	1
	${sequence:$i:1} $i ${aaRMd:6:1}
	1
	${sequence:$i:1} $i ${aaRMd:7:1}
	1
	${sequence:$i:1} $i ${aaRMd:8:1}
	1
	${sequence:$i:1} $i ${aaRMd:9:1}
	1
	${sequence:$i:1} $i ${aaRMd:10:1}
	1
	${sequence:$i:1} $i ${aaRMd:11:1}
	1
	${sequence:$i:1} $i ${aaRMd:12:1}
	1
	${sequence:$i:1} $i ${aaRMd:13:1}
	1
	${sequence:$i:1} $i ${aaRMd:14:1}
	1
	${sequence:$i:1} $i ${aaRMd:15:1}
	1
	${sequence:$i:1} $i ${aaRMd:16:1}
	1
	${sequence:$i:1} $i ${aaRMd:17:1}
	1
	${sequence:$i:1} $i ${aaRMd:18:1}
	EOFmut

	cat <<-EOFsh > ${path}/ddg_${fbname}_${i}.sh
	#!/bin/bash

	wget http://proxy.chtc.wisc.edu/SQUID/nwhoppe/database.tar.gz
	tar -xzvf database.tar.gz
	wget http://proxy.chtc.wisc.edu/SQUID/nwhoppe/ddg_monomer.static.linuxgccrelease

	chmod a+x ddg_monomer.static.linuxgccrelease
	./ddg_monomer.static.linuxgccrelease -database ./database @ddg_flags -in:file:s ${pdb} -ddg::mut_file ${fbname}_${i}.mutfile -ddg::iterations 50 > RUN_${fbname}_${i}_\${2}_\${1}.log

	rm -rf database/
	rm database.tar.gz
	rm ddg_monomer.static.linuxgccrelease
	EOFsh

	cat <<-EOFsub > ${path}/ddg_${fbname}_${i}.sub
	universe = vanilla
	log = CONDOR_${fbname}_${i}_\$(Cluster).log
	#error = CONDOR_${fbname}_${i}_\$(Cluster)_\$(Process).err
	#output = CONDOR_${fbname}_${i}_\$(Cluster)_\$(Process).out

	executable = ddg_${fbname}_${i}.sh
	arguments = \$(Process) \$(Cluster)
	
	should_transfer_files = YES
	when_to_transfer_output = ON_EXIT

	# Leave the queue if job exits w/ 0 (normal exit code), else re-run job
	on_exit_remove = ExitCode =?= 0

	# Put the job on hold if it tried too often
	on_exit_hold = JobRunCount > 5

	# Release held jobs if needed
	periodic_release = (JobStatus == 5) && ((CurrentTime - EnteredCurrentStatus) > 300) && (JobRunCount < 10) && (HoldReasonCode =!= 1) && (HoldReasonCode =!= 6) && (HoldReasonCode =!= 12) && (HoldReasonCode =!= 13) && (HoldReasonCode =!= 14) && (HoldReasonCode =!= 21) && (HoldReasonCode =!= 22)

	initialdir = ${path}/$i
	transfer_input_files = ${path}/ddg_flags, ${path}/input.cst, ${path}/${i}/${fbname}_${i}.mutfile, ${path}/${pdb}

	request_cpus = 1
	request_memory = 2GB
	request_disk = 2GB
	
	#+WantFlocking = true
	#+WantGlidein = true
	
	queue 1
	EOFsub
done
	
