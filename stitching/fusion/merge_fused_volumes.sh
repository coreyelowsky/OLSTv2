#!/bin/bash

echo ""
echo "###############################"
echo "Merge Fused Volumes Bash Script"
echo "###############################"
echo ""

# move log file
mv "$cur_dir"*merge_fusion_${out_res_z}um.* "$output_data_path"logs

if [ $start_from_oblique_to_coronal = false ];
then


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
		$imagej_exe --headless --console -macro $update_fused_image_resolution_macro "${output_data_path}isotropic?$out_res_z?$out_res_z?$out_res_z"

	fi


fi

# oblique to coronal
if [ $oblique_to_coronal = true ]
then

	# make output directory for isotropic
	mkdir -p $output_data_path"isotropic"

	# run oblique to coronal macro
	if [ $compute_full_res_fused_image = true ];
	then
		fused_target_name=fused_oblique_"$out_res_x"x"$out_res_y"x"$out_res_z".tif
	else
		fused_target_name=fused_oblique_"$out_res_z"x"$out_res_z"x"$out_res_z".tif
	fi

	arguments="$output_data_path?$fused_target_name?$shear_file?true?$input_orientation?$compute_full_res_fused_image"
	$imagej_exe --headless --console -macro $oblique_to_coronal_macro "$arguments"

	# crop sagittal 
	python $crop_fused_image_script "$output_data_path"isotropic?"sagittal"?$out_res_z?$out_res_z?$out_res_z

	if [ $input_orientation = "coronal" ];
	then
		# crop coronal
		python $crop_fused_image_script "$output_data_path"isotropic?"coronal"?$out_res_z?$out_res_z?$out_res_z

		# crop transverse
		python $crop_fused_image_script "$output_data_path"isotropic?"transverse"?$out_res_z?$out_res_z?$out_res_z
	fi


fi
