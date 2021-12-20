#!/bin/bash

echo ""
echo "#############"
echo "Saving as N5"
echo "#############"
echo ""

# move logs
mv "${cur_dir}save_as_n5."*${JOB_ID}* "${out_path_logs}logs/"

# job directory
job_directory="${in_path}volumes_${SGE_TASK_ID}/"
echo "Job Directory: ${job_directory}"

# save all volume in Z is n5
arguments="${job_directory}?${res_x}?${res_y}?${res_z}?${voxel_units}?${compression}?${subsampling_factors}?${block_sizes}?${threads_per_job}"

# run save as n5 script
$imagej_exe --headless --console -macro $save_n5_macro "$arguments"


echo ""
echo "Merge N5..."
echo ""


# calculate setup in whole dataset
output_setup=$((SGE_TASK_ID-1))

# move setups
source_path="${job_directory}/dataset.n5/setup0/"
dest_path="${out_path}/dataset.n5/setup${output_setup}"
mv $source_path $dest_path

# move attributes file
if [ "$SGE_TASK_ID" -eq "1" ];
then
	source_path="${job_directory}/dataset.n5/attributes.json"
	dest_path="${out_path}/dataset.n5/"
	mv $source_path $dest_path
fi


# move volumes back
echo "Move volumes back to original location..."
mv "${in_path}volumes_${SGE_TASK_ID}/Z"* $in_path_volumes
echo ""

# delete folder
echo "Remove Folders..."
rm -rf "${in_path}volumes_${SGE_TASK_ID}/"
echo ""

echo "Completed!"
echo ""


