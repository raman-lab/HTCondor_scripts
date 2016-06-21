# script to make dagman.dag file for all sub files in current directory

#!/bin/bash

dagName='SuperDagMan.dag'
shopt -s nullglob
fileArr=(*.sub)

while [ "$1" != "" ]
do
	echo "$1"
	case "$1" in 
		-f | --fileList)	
			shift
			fileArr=($1);;
		-n | --name)
			shift
			dagName="$1";;
		* )
			echo "Invalid Argument"
                        echo
                        echo "Valid arguments are:"
                        echo "-f | --fileList <'wildcard sub files'> default is '*.sub'"
                        echo "-n | --name <'name of dag file.dag'> default is 'SuperDagMan.dag'"
			exit;;
	esac
	shift
done

lenFileArr=${#fileArr[@]}
seqArr=($(seq -w 0 $lenFileArr))
echo CONFIG dagman_config > "$dagName"

for ((i=0;i<$lenFileArr;i++));
do
	echo "Job ${seqArr[$i]} ${fileArr[$i]}"
done >> "$dagName"
