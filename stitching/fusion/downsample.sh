#!/bin/bash

echo ""
echo "######################"
echo "Dowsnample Bash Script"
echo "######################"
echo ""

# move log files
sleep 5
mv "${cur_dir}"*${JOB_ID}* ${log_path}

export input_image_path=${full_res_path}fused_${SGE_TASK_ID}.tif
export output_image_path=${isotropic_path}fused_${SGE_TASK_ID}.tif
export delete=true

# run dowsnample
$imagej_exe --headless --console -macro $downsample_macro "${input_image_path}?${output_image_path}?${delete}"

