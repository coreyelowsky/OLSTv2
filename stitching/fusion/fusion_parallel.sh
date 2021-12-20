#!/bin/bash

echo ""
echo "######"
echo "Fusion"
echo "######"
echo ""

# move log files
sleep 5
mv "${cur_dir}"*${JOB_ID}* "$output_data_path"logs

# output path of fused image that big stitcher will save
fused_image_out_path="$output_data_path${SGE_TASK_ID}_fused_tp_0_ch_0.tif"

# run fusion
$imagej_exe --headless --console -macro $fusion_parallel_macro "$input_data_path?$output_data_path?$xml_file_name?$downsampling?$pixel_type?$interpolation?$blend?${SGE_TASK_ID}?$grid_size?$compute_full_res_fused_image"


