#!/bin/bash

# This is the main script to run for prepocessing volumes for stitching
# Volumes are concatenated, rotated by 90 degrees, and reversed in Z dimension

####################################
######## For User to Modify ########
####################################

# input and output data directories
export input_data_path=/grid/osten/data_norepl/qi/rawdata/AVP/AVP-IHC-A3/
export output_data_path=/grid/osten/data_norepl/elowsky/concat_test/

# preprocessing steps
export flip_z=true
export rotate=true

# how to downsample
export downsample=false
export downsample_xy=2

# directories prefix string
export dir_prefix='ch1_Z_'

# if only want to process certain folders
# set processAllZFolders=false
# and set startZ and endZ accordingly
# if true, then startZ and endZ are ignored
# export process_all_z_folders=true
export process_all_z_folders=false

# ignore if processing all folders
export start_z=3
export end_z=5
export start_y=7
export end_y=8


# amount of memory in GB per job
export memory_per_job=35

# how many threads per job
export threads_per_job=8

#####################################
#####################################
#####################################

# get base directory and
export base_dir=$(dirname $0)/../../

# get current directory
export cur_dir=`pwd`"/"

# set up script paths
export concat_rotate_flip_script="${base_dir}stitching/concat_rotate_flipz/concat_rotate_flipz.sh"
export concat_rotate_flip_macro="${base_dir}stitching/concat_rotate_flipz/concat_rotate_flipz.ijm"

# import parameters and functions
source "${base_dir}stitching/stitching_params.sh"

# check if running on cluster
is_running_on_cluster $HOSTNAME

# calculate amount of memory per thread
export memory_per_thread_per_job=$((memory_per_job/threads_per_job+1))

# create output directories
export output_data_path_volumes="${output_data_path}volumes/"
mkdir -p $output_data_path_volumes

export output_data_path_logs="${output_data_path}concat_rotate_flipz/"
mkdir -p $output_data_path_logs

# copy fiji
cp -r $fiji_path $output_data_path_logs
export imagej_exe=${output_data_path_logs}Fiji.app/ImageJ-linux64
chmod +x $imagej_exe


echo ""
echo "###########################"
echo "Concat Rotate FlipZ Stacks"
echo "###########################"
echo ""
echo "Input Data Path: ${input_data_path}"
echo "Output Data Path: ${output_data_path}"
echo "Memory Per Job: ${memory_per_job}G"
echo "# Threads per Job: ${threads_per_job}"
echo "Memory Per Thread per Job: ${memory_per_thread_per_job}G"
if [ $downsample = true ];
then
	echo "# Downsampling in xy: ${downsample_xy}"
fi
echo ""

# calculate num_y_per_z
export num_stacks_per_volume=$(ls "${input_data_path}${dir_prefix}1/"*"Pos0"* | wc -l)
export num_files_in_folder=$(ls "${input_data_path}${dir_prefix}1/" | wc -l)
export num_y_per_z=$((num_files_in_folder / num_stacks_per_volume))

# logic to decide which z folders to process
if [ $process_all_z_folders = true ];
then
	echo "Processing all folders..."
	echo ""
	export num_z_folders=$(find $input_data_path -maxdepth 1 -name "${dir_prefix}*" | wc -l)
	export start_z=1
	export end_z=$num_z_folders
	export start_y=1
	export end_y=$num_y_per_z
else
	export num_z_folders=$((end_z-start_z+1))
	export num_y_per_z=$((end_y-start_y+1))
fi

echo "# Z Folders: ${num_z_folders}"
echo "Start Z: ${start_z}"
echo "End Z: ${end_z}"
echo "Start Y: ${start_y}"
echo "End Y: ${end_y}"
echo ""


echo "Write Parameters..."
echo "" >> "${output_data_path_logs}params.txt"
echo "Input Data Path: ${input_data_path}" >> "${output_data_path_logs}params.txt"
echo "Output Data Path: $output_data_path" >> "${output_data_path_logs}params.txt"
echo "Flip Z: ${flip_z}" >> "${output_data_path_logs}params.txt"
echo "Rotate: ${rotate}" >> "${output_data_path_logs}params.txt"
echo "Process All Folders: ${process_all_z_folders}" >> "${output_data_path_logs}params.txt"
echo "Start Z: ${start_z}" >> "${output_data_path_logs}params.txt"
echo "End Z: ${end_z}" >> "${output_data_path_logs}params.txt"
echo "Start Y: ${start_y}" >> "${output_data_path_logs}params.txt"
echo "End Y: ${end_y}" >> "${output_data_path_logs}params.txt"
if [ $downsample = true ];
then
	echo "# Downsampling in xy: ${downsample_xy}" >> "${output_data_path_logs}params.txt"
fi

echo "" >> "${output_data_path_logs}params.txt"
echo ""


# if running on cluster, need to call qsub array job
# otherwise, call imagej macro
if [ $cluster = true ];
then


	echo "# stacks per volume: ${num_stacks_per_volume}"
	echo "# files in folder: ${num_files_in_folder}"
	echo "# y per z: ${num_y_per_z}"
	echo "# z: ${num_z_folders}"

	# calculate how many jobs to run
	# always run max amount but will ignore later if needed
	export num_jobs=$((num_z_folders * num_y_per_z))
	echo "# Jobs: ${num_jobs}"
	echo ""

	# create logs directory
	mkdir -p "${output_data_path_logs}logs/"

	# update memory and threads for imagej
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "${memory_per_job}?${imagej_threads}"

	# call qsub to set off array job
	qsub -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free=$((2*memory_per_thread_per_job))G -t 1-$num_jobs $concat_rotate_flip_script
else

	# NEED TO DEVELOP #

	# NOT RUNNING ON CLUSTER #

	echo "Need to develop"
	
	# Never delete input data when not running on cluster
	#delete_input_data=false
	# update memory and threads for imagej
	#$imageJEXE --headless --console -macro $updateImageJMemoryMacro "$memory_concatRotateFlipz?$imageJThreads"
	# run imagej macro to concat, rotate, flipz stacks
	#$imageJEXE --headless --console -macro $concatRotateFlipMacro "$inputDataPath?$outputDataPath?$flipZ?$rotate?$deleteInputData?$startZ?$endZ"

fi




