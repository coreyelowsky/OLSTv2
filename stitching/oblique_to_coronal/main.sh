#!/bin/bash

# This is the main script to run converting a fused image from oblique to coronal orientation

####################################
######## For User to Modify ########
####################################

export input_volume_name='Z14_Y09'
export input_volume_path=/mnt/nfs/grids/hpc_norepl/qi/data/GAD2/GAD2-GFP-M4/volumes/
export output_volume_path=/data/elowsky/

export in_res_x=.78
export in_res_y=.78
export in_res_z=2.5

export downsample_to_isotropic=true

#####################################
#####################################
#####################################

echo ""
echo "###################"
echo "Oblique to Coronal"
echo "###################"
echo ""

# get current directory
export cur_dir=`pwd`"/"

# get base directory
export base_dir=$(dirname $0)/../../

# get base directory
export baseDir=$(dirname $0)/../

# set up script paths
export modify_resolution_macro="$base_dir"stitching/oblique_to_coronal/modify_image_resolution.ijm
export downsample_to_isotropic_macro="$base_dir"stitching/oblique_to_coronal/downsample_to_isotropic.ijm
export reslice_macro="$base_dir"stitching/oblique_to_coronal/reslice.ijm
export shear_macro="$base_dir"stitching/oblique_to_coronal/shear.ijm
export rotate_macro="$base_dir"stitching/oblique_to_coronal/rotate.ijm

echo "Input Volune Name: ${input_volume_name}"
echo "Input Volume Path: ${input_volume_path}"
echo "Output Volume Path: ${output_volume_path}"
echo  ""

# import parameters
source "$base_dir"stitching/stitching_params.sh

# get size of volume
export volume_size_bytes=`du -bc ${input_volume_path}${input_volume_name}.tif | tail -1 | sed -e 's/\s.*$//'`
export volume_size_gb=$(echo "$volume_size_bytes/1024/1024/1024" | bc -l)
export volume_size_gb=`python -c "from math import ceil; print(ceil($volume_size_gb))"`


# upper bound estimate for imagej memory needed
export imagej_memory=$((volume_size_gb*5))

echo "Volume Size: ${volume_size_gb} GB"
echo "ImageJ Memory: ${imagej_memory} GB"
echo ""

export imagej_exe=${fiji_path}/ImageJ-linux64

# update memory and threads for imagej
$imagej_exe --headless --console -macro $update_imagej_memory_macro "$imagej_memory?$imagej_threads"


# make sure image resolution is set properly......
modify_res_input_path=${input_volume_path}${input_volume_name}.tif
modify_res_output_path=${output_volume_path}${input_volume_name}_modified_resolution.tif
$imagej_exe --headless --console -macro $modify_resolution_macro "${modify_res_input_path}?${modify_res_output_path}?${in_res_x}?${in_res_y}?${in_res_z}"


# downsample
if [ $downsample_to_isotropic = true ];
then
	downsample_input_path=${modify_res_output_path}
	downsample_output_path=${output_volume_path}${input_volume_name}_downsampled_to_isotropic.tif
	$imagej_exe --headless --console -macro $downsample_to_isotropic_macro "${downsample_input_path}?${downsample_output_path}?${in_res_x}?${in_res_y}?${in_res_z}"

	reslice_input_path=${downsample_output_path}
	downsample_string='_isotropic'	

else
	reslice_input_path=${modify_res_output_path}
	downsample_string='_full_res'
fi

# reslice/vertical flip
reslice_output_path=${output_volume_path}${input_volume_name}_reslice_vertical_flip${downsample_string}.tif
export reslice_flip=true
export reslice_direction="Left"
$imagej_exe --headless --console -macro $reslice_macro "${reslice_input_path}?${reslice_output_path}?${reslice_flip}?${reslice_direction}"

# shear
shear_input_path=$reslice_output_path
shear_output_path=${output_volume_path}${input_volume_name}_sagittal${downsample_string}.tif
$imagej_exe --headless --console -macro $shear_macro "${shear_input_path}?${shear_output_path}?${shear_file}"

# reslice/vertical flip
sagittal_resliced_input_path=${shear_output_path}
sagittal_resliced_output_path=${output_volume_path}${input_volume_name}_sagittal_resliced${downsample_string}.tif
export reslice_flip=false
export reslice_direction="Left"
$imagej_exe --headless --console -macro $reslice_macro "${sagittal_resliced_input_path}?${sagittal_resliced_output_path}?${reslice_flip}?${reslice_direction}"

# rotate
rotate_input_path=${sagittal_resliced_output_path}
rotate_output_path=${output_volume_path}${input_volume_name}_coronal${downsample_string}.tif
$imagej_exe --headless --console -macro $rotate_macro "${rotate_input_path}?${rotate_output_path}"







