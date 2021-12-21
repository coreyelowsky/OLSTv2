#!/bin/bash

echo ""
echo "###############################"
echo "Merge Fused Volumes Bash Script"
echo "###############################"
echo ""

# move log file
mv "$cur_dir"*merge_fusion_${out_res_z}um.* "$output_data_path"logs


if [ $compute_full_res_fused_image = true ]
then
	# python script to merge volumes
	python $merge_fused_volumes_python_script $output_data_path $downsampling $grid_size $out_res $compute_full_res_fused_image

	# update resolution of merged fused image
	$imagej_exe --headless --console -macro $update_fused_image_resolution_macro "$output_data_path?$out_res_x?$out_res_y?$out_res_z"

else

	mkdir -p $output_data_path"isotropic"

	# python script to merge volumes
	python $merge_fused_volumes_python_script $output_data_path $downsampling $grid_size $out_res_isotropic $compute_full_res_fused_image

	# update resolution of merged fused image
	$imagej_exe --headless --console -macro $update_fused_image_resolution_macro "${output_data_path}isotropic/?${out_res_z}?${out_res_z}?${out_res_z}"

fi
