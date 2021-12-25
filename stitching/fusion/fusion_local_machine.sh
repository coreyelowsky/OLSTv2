#!/bin/bash

# set parallel to false
export parallel=false
export xml_full_path=${input_data_path}${xml_file_name}.xml
export fusion_out_path=$full_res_path
export fusion_out_path_full=${fusion_out_path}fused_oblique_${out_res}.tif
export downsample_out_path=${isotropic_path}fused_oblique_${out_res_isotropic}.tif


if [ $start_from_downsample = false -a $start_from_oblique_to_coronal = false ];
then

	# update memory and threads for imagej
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$fusion_memory?$imagej_threads"

	# run fusion
	$imagej_exe --headless --console -macro $fusion_macro "${xml_full_path}?${fusion_out_path}?${xml_file_name}?${downsampling}?${pixel_type}?${interpolation}?${blend}?0?0?${parallel}"

	# rename fused image
	mv ${fusion_out_path}fused_tp_0_ch_0.tif $fusion_out_path_full

fi


if [ $start_from_oblique_to_coronal = false ];
then

	# calculate fused image size
	export fused_image_size_bytes=`du -bc "${fusion_out_path}fused"*.tif | tail -1 | sed -e 's/\s.*$//'`
	export fused_image_size_gb=$(echo "$fused_image_size_bytes/1000/1000/1000" | bc -l)
	export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

	echo "Fused Image Size: ${fused_image_size_bytes} bytes"
	echo "Fused Image Size: ${fused_image_size_gb} GB"
	echo "Fused Image Size (rounded up): ${fused_image_size} GB"

	# multuply by 2 for safe upper bound
	export downsample_memory=$((fused_image_size*2))
	echo "Downsample Memory (upper bound): ${downsample_memory} GB"

	# update memory and threads for imagej
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$downsample_memory?$imagej_threads"

	# downsample
	delete=false
	$imagej_exe --headless --console -macro $downsample_macro "${fusion_out_path_full}?${downsample_out_path}?${delete}"

fi

if [ $oblique_to_coronal = true ];
then

	echo ""
	echo "Reslice + Vertical Flip...."
	echo ""

	export input_image_path="${isotropic_path}fused_oblique_${out_res_z}x${out_res_z}x${out_res_z}.tif"
	export output_image_path="${isotropic_path}fused_oblique_resliced_${out_res_z}x${out_res_z}x${out_res_z}.tif"
	export flip=true
	export direction="Left"

	$imagej_exe --headless --console -macro $reslice_macro "${input_image_path}?${output_image_path}?${flip}?${direction}"

	echo ""
	echo "Shear..."
	echo ""

	export input_image_path=$output_image_path
	if [ $input_orientation = "coronal" ];
	then
		export output_image_path="${isotropic_path}fused_sagittal_${out_res_z}x${out_res_z}x${out_res_z}.tif"

	elif [ $input_orientation = "sagittal" ];
	then
		export output_image_path="${isotropic_path}fused_sheared_${out_res_z}x${out_res_z}x${out_res_z}.tif"
	else
		echo "Invalid input orientation...cant shear..."
	fi
	export output_image_path="${isotropic_path}fused_sagittal_${out_res_z}x${out_res_z}x${out_res_z}.tif"

	$imagej_exe --headless --console -macro $shear_macro "${input_image_path}?${output_image_path}?${shear_file}"


	echo ""
	echo "Reslice...."
	echo ""

	export input_image_path=$output_image_path
	if [ $input_orientation = "coronal" ];
	then
		export output_image_path="${isotropic_path}fused_sagittal_resliced_${out_res_z}x${out_res_z}x${out_res_z}.tif"

	elif [ $input_orientation = "sagittal" ];
	then
		export output_image_path="${isotropic_path}fused_sagittal_${out_res_z}x${out_res_z}x${out_res_z}.tif"
	else
		echo "Invalid input orientation...cant shear..."
	fi

	export output_image_path="${isotropic_path}fused_sagittal_resliced_${out_res_z}x${out_res_z}x${out_res_z}.tif"
	export flip=false
	export direction="Left"

	$imagej_exe --headless --console -macro $reslice_macro "${input_image_path}?${output_image_path}?${flip}?${direction}"

	if [ $input_orientation = "coronal" ];
	then

		echo ""
		echo "Rotate...."
		echo ""

		export input_image_path=$output_image_path
		export output_image_path="${isotropic_path}fused_coronal_${out_res_z}x${out_res_z}x${out_res_z}.tif"

		$imagej_exe --headless --console -macro $rotate_macro "${input_image_path}?${output_image_path}"

		echo ""
		echo "Reslice...."
		echo ""

		export input_image_path=$output_image_path
		export output_image_path="${isotropic_path}fused_transverse_${out_res_z}x${out_res_z}x${out_res_z}.tif"
		export flip=false
		export direction="Top"

		$imagej_exe --headless --console -macro $reslice_macro "${input_image_path}?${output_image_path}?${flip}?${direction}"


	fi

	echo ""
	echo "Crop Sagittal...."
	echo ""

	export input_image_path="${isotropic_path}fused_sagittal_${out_res_z}x${out_res_z}x${out_res_z}.tif"
	export output_image_path="${isotropic_path}fused_sagittal_${out_res_z}x${out_res_z}x${out_res_z}_CROPPED.tif"
	export crop_res_x=${out_res_z}
	export crop_res_y=${out_res_z}
	export crop_res_z=${out_res_z}

	python $crop_python_script "${input_image_path}?${output_image_path}?${isotropic_path}?${crop_res_x}?${crop_res_y}?${crop_res_z}"

	if [ $input_orientation = "coronal" ];
	then

		echo ""
		echo "Crop Coronal...."
		echo ""

		export input_image_path="${isotropic_path}fused_coronal_${out_res_z}x${out_res_z}x${out_res_z}.tif"
		export output_image_path="${isotropic_path}fused_coronal_${out_res_z}x${out_res_z}x${out_res_z}_CROPPED.tif"
		export crop_res_x=${out_res_z}
		export crop_res_y=${out_res_z}
		export crop_res_z=${out_res_z}

		python $crop_python_script "${input_image_path}?${output_image_path}?${isotropic_path}?${crop_res_x}?${crop_res_y}?${crop_res_z}"

		echo ""
		echo "Crop Transverse..."
		echo ""

		export input_image_path="${isotropic_path}fused_transverse_${out_res_z}x${out_res_z}x${out_res_z}.tif"
		export output_image_path="${isotropic_path}fused_transverse_${out_res_z}x${out_res_z}x${out_res_z}_CROPPED.tif"
		export crop_res_x=${out_res_z}
		export crop_res_y=${out_res_z}
		export crop_res_z=${out_res_z}

		python $crop_python_script "${input_image_path}?${output_image_path}?${isotropic_path}?${crop_res_x}?${crop_res_y}?${crop_res_z}"

	fi

fi 


