#!/bin/bash

echo ""
echo "######"
echo "Fusion"
echo "######"
echo ""

# move log files
mv "$cur_dir"*"$job_name".* $output_data_path

# run fusion
$imagej_exe --headless --console -macro $fusion_macro "$input_data_path?$output_data_path?$xml_file_name?$downsampling?$pixel_type?$interpolation?$blend"

# move fusion result
fused_target_name=fused_oblique_"$out_res_x"x"$out_res_y"x"$out_res_z".tif
mv "$output_data_path"fused_tp_0_ch_0.tif $output_data_path$fused_target_name
