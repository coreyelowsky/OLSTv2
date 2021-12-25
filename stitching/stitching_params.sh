#!/bin/bash

# host names for cluster nodes
cluster_host_names=("bamdev1" "bamdev2")

# ImageJ executable
export fiji_path="$base_dir"applications/Fiji.app/
export imagej_threads=48

# ImageJ script to update memory and threads 
export update_imagej_memory_macro="$base_dir"stitching/update_imagej_memory_and_threads.ijm
export wait_for_jobs_to_complete_script="$base_dir"stitching/wait_for_jobs_to_complete.sh

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









