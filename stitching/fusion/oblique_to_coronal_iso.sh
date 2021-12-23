#!/bin/bash

echo ""
echo "##############################################"
echo "Oblique to Coronal Full Resolution Bash Script"
echo "##############################################"
echo ""


# move log file
mv "$cur_dir"*oblique_to_coronal_${out_res_z}um.* "$output_data_path"logs

# run oblique to coronal macro
if [ $compute_full_res_fused_image = false ];
then
	arguments="$output_data_path?$fused_target_name?$shear_file?true?$input_orientation?$compute_full_res_fused_image?$out_res_z?$out_res_z?$out_res_z"
else
	arguments="$output_data_path?$fused_target_name?$shear_file?true?$input_orientation?$compute_full_res_fused_image?$out_res_x?$out_res_y?$out_res_z"
fi

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



