#!/bin/bash

echo ""
echo "######################"
echo "Dowsnample Bash Script"
echo "######################"
echo ""

# move log file
sleep 5
mv "$cur_dir"*downsample_${out_res_z}um.* "$output_data_path"logs

export input_image_path=${output_data_path}fused_${SGE_TASK_ID}.tif
export output_image_path=${output_data_path}/isotropic/fused_${SGE_TASK_ID}.tif

# run dowsnample
$imagej_exe --headless --console -macro $downsample_macro "${input_image_path}?${output_image_path}"

