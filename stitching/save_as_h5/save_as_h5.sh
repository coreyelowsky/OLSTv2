#!/bin/bash

echo ""
echo "#############"
echo "Saving as H5"
echo "#############"
echo ""

# move logs
mv "${cur_dir}save_as_h5."*${JOB_ID}* "${out_path_logs}logs/"

# job directory
job_directory="${in_path}volumes_${SGE_TASK_ID}/"
echo "Job Directory: ${job_directory}"

# save all volume in Z is n5
arguments="${job_directory}?${res_x}?${res_y}?${res_z}?${voxel_units}?${subsampling_factors}?${block_sizes}"

# run save as n5 script
$imagej_exe --headless --console -macro $save_h5_macro "$arguments"




