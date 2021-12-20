#!/bin/bash

echo ""
echo "################################################"
echo "Obliqyue to Coronal Full Resolution Bash Script"
echo "################################################"
echo ""


# move log file
mv "$input_data_path"*oblique_to_coronal_isotropic_$downsampling.* "$output_data_path"

# make output directory for isotropic
mkdir $output_data_path"isotropic"

# run oblique to coronal macro
fused_target_name=fused_oblique_"$out_res_x"x"$out_res_y"x"$out_res_z".tif
arguments="$output_data_path?$fused_target_name?$shear_file?true"
$imagej_exe --headless --console -macro $oblique_to_coronal_macro "$arguments"

# crop sagittal 
python $crop_fused_image_script "$output_data_path"isotropic?"sagittal"?$out_res_z?$out_res_z?$out_res_z

# crop coronal
python $crop_fused_image_script "$output_data_path"isotropic?"coronal"?$out_res_z?$out_res_z?$out_res_z

# crop transverse
python $crop_fused_image_script "$output_data_path"isotropic?"transverse"?$out_res_z?$out_res_z?$out_res_z


