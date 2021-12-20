#!/bin/bash

echo ""
echo "################################################"
echo "Oblique to Coronal Full Resolution Bash Script"
echo "################################################"
echo ""


# move log file
if [ $parallel = true ];
then
	mv "$input_data_path"*oblique_to_coronal_full_res_$downsampling.* "$output_data_path"logs
else
	mv "$input_data_path"*oblique_to_coronal_full_res_$downsampling.* "$output_data_path"
fi


# make output directory for isotropic
mkdir $output_data_path"full_res"

# run oblique to coronal macro
fused_target_name=fused_oblique_"$out_res_x"x"$out_res_y"x"$out_res_z".tif
arguments="$output_data_path?$fused_target_name?$shear_file?false?$input_orientation?true"
$imagej_exe --headless --console -macro $oblique_to_coronal_macro "$arguments"

# crop sagittal 
python $crop_fused_image_script "$output_data_path"full_res?"sagittal"?$out_res_y?$out_res_z?$out_res_x

# crop coronal
python $crop_fused_image_script "$output_data_path"full_res?"coronal"?$out_res_x?$out_res_z?$out_res_y

# crop transverse
python $crop_fused_image_script "$output_data_path"full_res?"transverse"?$out_res_x?$out_res_y?$out_res_z


