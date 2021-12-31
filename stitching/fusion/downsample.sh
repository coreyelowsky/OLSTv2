#!/bin/bash

echo ""
echo "######################"
echo "Dowsnample Bash Script"
echo "######################"
echo ""

# move log files
sleep 5
mv "${cur_dir}"*${JOB_ID}* ${log_path}

if [ $grid = true ];
then
	export input_image_path=${full_res_path}fused_${SGE_TASK_ID}.tif
	export output_image_path=${isotropic_path}fused_${SGE_TASK_ID}.tif
	export delete=true
else
	export input_image_path=${full_res_path}fused_oblique_${out_res_x}x${out_res_y}x${out_res_z}.tif
	export output_image_path=${isotropic_path}fused_oblique_${out_res_z}x${out_res_z}x${out_res_z}.tif
	export delete=false

fi


# make sure fused volume exists
if [ ! -f $input_image_path ];
then

	echo "Fused volume does not exist - ${input_image_path}"
	exit
fi

# check if dowsnampled volume already exists
if [ -f $output_image_path ];
then

	echo "Output volume already exists - ${output_image_path}"
	exit
fi

# run dowsnample
$imagej_exe --headless --console -macro $downsample_macro "${input_image_path}?${output_image_path}?${delete}"

