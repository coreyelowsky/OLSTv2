#!/bin/bash

echo ""
echo "######"
echo "Fusion"
echo "######"
echo ""

# move log files
sleep 5
mv "${cur_dir}"*${JOB_ID}* ${log_path}

if [ -f ${fusion_out_path}fused_${SGE_TASK_ID}.tif ];
then

	echo "Fused volume already exists...."
	exit
fi

# run fusion
$imagej_exe --headless --console -macro $fusion_macro "${xml_full_path}?${fusion_out_path}?${xml_file_name}?${downsampling}?${pixel_type}?${interpolation}?${blend}?${SGE_TASK_ID}?${grid_size}?${parallel}"


