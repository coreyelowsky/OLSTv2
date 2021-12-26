#!/bin/bash

echo ""
echo "####################"
echo "Concat Rotate Flip Z"
echo "####################"
echo ""

# move log files
mv "$cur_dir"concat_rotate_flipz.sh.*${JOB_ID}* "$output_data_path_logs"logs

# calculate z and y
z_id=$(((SGE_TASK_ID-1) / num_y + start_z))
z_folder_path=${input_data_path}${dir_prefix}${z_id}/
y_id=$(((SGE_TASK_ID-1) % num_y + 1))

echo "Z id: ${z_id}"
echo "Y id: ${y_id}"
echo "Z folder path: ${z_folder_path}"

# run imagej macro to concat, rotate, flipz stacks
$imagej_exe --headless --console -macro $concat_rotate_flip_macro "$z_folder_path?$output_data_path_volumes/?$flip_z?$rotate?$dir_prefix?$downsample?$downsample_xy?$z_id?$y_id?$num_stacks_per_volume"


