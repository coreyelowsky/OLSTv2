#!/bin/bash

echo ""
echo "###############################"
echo "Merge Fused Volumes Bash Script"
echo "###############################"
echo ""

# move log file
mv "$cur_dir"*merge_fusion_${out_res_z}um.* $log_path


if [ $compute_full_res_fused_image = true ]
then

	export input_image_path=${output_data_path}
	export output_image_path=${output_data_path}	

	# python script to merge volumes
	python $merge_fused_volumes_python_script $input_image_path $output_image_path $downsampling $grid_size $out_res 

else

	mkdir -p $output_data_path"isotropic"

	export input_image_path=${output_data_path}isotropic/
	export output_image_path=${output_data_path}isotropic/

	# python script to merge volumes
	python $merge_fused_volumes_python_script $input_image_path $output_image_path $downsampling $grid_size $out_res_isotropic

fi
