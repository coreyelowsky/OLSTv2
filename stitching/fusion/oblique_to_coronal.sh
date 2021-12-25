#!/bin/bash

echo ""
echo "##############################"
echo "Oblique to Coronal Bash Script"
echo "##############################"
echo ""


# move log file
mv "$cur_dir"*oblique_to_coronal_${out_res_z}um.* "$output_data_path"logs

# set up arguments
arguments="$oblique_to_coronal_inpath?$fused_target_name?$shear_file?$input_orientation?$out_res_z?$out_res_z?$out_res_z"

# run oblique to coronal macro
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



