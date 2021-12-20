#!/bin/bash

# host names for cluster nodes
cluster_host_names=("bamdev1" "bamdev2")

# ImageJ executable
export fiji_path="$base_dir"applications/Fiji.app/
export imagej_threads=48

# ImageJ script to update memory and threads 
export update_imagej_memory_macro="$base_dir"stitching/update_imagej_memory_and_threads.ijm

# oblique to coronal params
export shear_file="$base_dir"stitching/oblique_to_coronal/shear_isotropic.txt


# function that exports boolean cluster variable based on whether scripts
# are running on cluster or not and also exports relevant variables
is_running_on_cluster(){

	if [[ " ${cluster_host_names[@]} " =~ " $1 " ]];
	then
		echo ""
		echo "###################"
		echo "Running on Cluster!"
		echo "###################"
		export cluster=true

	else
		echo ""
		echo "Running on Local Machine!"
		export cluster=false
	fi
}

# function to distribute jobs among workers
# as evenly as possible
distribute_jobs(){

	local num_jobs=$1
	local num_workers=$2	

	# initialize array 
	for i in $(seq 0 $((num_workers-1)))
	do
		job_array[$i]=0
	done


	# increment jobs
	idx=0
	while [ $num_jobs -ne 0 ]
	do
		job_array[$idx]=$((job_array[$idx]+1))
		num_jobs=$((num_jobs-1))
	
		if [ $idx -eq $((num_workers-1)) ]
		then
			idx=0
		else
			idx=$((idx+1))
		fi
	done
}

export -f distribute_jobs









