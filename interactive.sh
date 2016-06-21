# Script to be transfered into an interactive condor job
# runs commands up to rosetta command found in an executable file used for enzdes protocol then echos the appropriate rosetta command
#!/bin/bash

wget http://proxy.chtc.wisc.edu/SQUID/nwhoppe/database.tar.gz
tar -xzvf database.tar.gz
wget http://proxy.chtc.wisc.edu/SQUID/nwhoppe/rosetta_scripts.linuxgccrelease

chmod a+x rosetta_scripts.linuxgccrelease
echo "./rosetta_scripts.linuxgccrelease -database ./database -parser::protocol enzdes.xml -in::file::s 2uxo_Chrys_A0_P2_C0.pdb -extra_res_fa LG.params @enzdes_flags -parser::script_vars ligchain=X resfile=B1tetR.resfile -packing::unboundrot 2uxo_Chrys_A0_P2_C0.pdb -out:file:o 2uxo_Chrys_A0_P2_C0_B1_Test.pdb -out:suffix _Test -scorefile score_2uxo_Chrys_A0_P2_C0_B1_Test.sc -nstruct 2 > RUN_test.log"
