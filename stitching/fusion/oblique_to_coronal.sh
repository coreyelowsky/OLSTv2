#!/bin/bash

echo ""
echo "##############################"
echo "Oblique to Coronal Bash Script"
echo "##############################"
echo ""

echo "Res X: ${obc_res_x}"
echo "Res Y: ${obc_res_y}"
echo "Res Z: ${obc_res_z}"
echo ""

# Reslice + Vertical Flip

# get size of image
export input_image_path="${obc_inpath}fused_oblique_${obc_res_x}x${obc_res_y}x${obc_res_z}.tif"
export output_image_path="${obc_inpath}fused_oblique_resliced_${obc_res_y}x${obc_res_z}x${obc_res_x}.tif"
export flip=true
export direction="Left"

# if input image doesnt exist
# then exit
if [ ! -f $input_image_path ];
then
	echo "Error: Image Does Not Exist - ${input_image_path}"
	exit
fi

if [ ! -f $output_image_path ];
then

	echo ""
	echo "Reslice + Vertical Flip...."
	echo ""

	export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
	export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1024/1024/1024" | bc -l)
	export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

	echo "Fused Image Size: ${fused_image_size_bytes} bytes"
	echo "Fused Image Size: ${fused_image_size_gb} GB"
	echo "Fused Image Size (rounded up): ${fused_image_size} GB"

	export oblique_to_coronal_memory=$((fused_image_size*3))
	echo "Oblique to Coronal Memory (safe upper bound): ${oblique_to_coronal_memory} GB"

	# update memory and threads for imagej
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$oblique_to_coronal_memory?$imagej_threads"	

	export job_name="obc_reslice_vert_${obc_res_z}um"
	export memory_per_thread=$((oblique_to_coronal_memory/threads_per_job + 1))

	echo "Job Name: ${job_name}"
	echo "Memory Per Thread: ${memory_per_thread}"
	export qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -p ${priority} $reslice_bash_script`

	source $wait_for_jobs_to_complete_script

fi


# Shear

export input_image_path=$output_image_path
if [ $input_orientation = "coronal" ];
then
	export output_image_path="${obc_inpath}fused_sagittal_${obc_res_y}x${obc_res_z}x${obc_res_x}.tif"

elif [ $input_orientation = "sagittal" ];
then
	export output_image_path="${obc_inpath}fused_sheared_${obc_res_y}x${obc_res_z}x${obc_res_x}.tif"
else
	echo "Invalid input orientation...cant shear..."
fi

if [ ! -f $output_image_path ];
then

	echo ""
	echo "Shear..."
	echo ""

	export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
	export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1024/1024/1024" | bc -l)
	export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

	echo "Fused Image Size: ${fused_image_size_bytes} bytes"
	echo "Fused Image Size: ${fused_image_size_gb} GB"
	echo "Fused Image Size (rounded up): ${fused_image_size} GB"

	export oblique_to_coronal_memory=$((fused_image_size*4))
	echo "Oblique to Coronal Memory (safe upper bound): ${oblique_to_coronal_memory} GB"

	# update memory and threads for imagej
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$oblique_to_coronal_memory?$imagej_threads"	

	export job_name="obc_shear_${obc_res_z}um"
	export memory_per_thread=$((oblique_to_coronal_memory/threads_per_job + 1))

	echo "Job Name: ${job_name}"
	echo "Memory Per Thread: ${memory_per_thread}"
	export qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -p ${priority} $shear_bash_script`

	source $wait_for_jobs_to_complete_script

fi


# Reslice

export input_image_path=$output_image_path
if [ $input_orientation = "coronal" ];
then
	export output_image_path="${obc_inpath}fused_sagittal_resliced_${obc_res_z}x${obc_res_x}x${obc_res_y}.tif"

elif [ $input_orientation = "sagittal" ];
then
	export output_image_path="${obc_inpath}fused_sagittal_${obc_res_z}x${obc_res_x}x${obc_res_y}.tif"
else
	echo "Invalid input orientation...cant reslice..."
fi

export flip=false
export direction="Left"

if [ ! -f $output_image_path ];
then

	echo ""
	echo "Reslice..."
	echo ""

	export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
	export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1024/1024/1024" | bc -l)
	export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

	echo "Fused Image Size: ${fused_image_size_bytes} bytes"
	echo "Fused Image Size: ${fused_image_size_gb} GB"
	echo "Fused Image Size (rounded up): ${fused_image_size} GB"

	export oblique_to_coronal_memory=$((fused_image_size*3))
	echo "Oblique to Coronal Memory (safe upper bound): ${oblique_to_coronal_memory} GB"

	# update memory and threads for imagej
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$oblique_to_coronal_memory?$imagej_threads"	

	export job_name="obc_reslice_${obc_res_z}um"
	export memory_per_thread=$((oblique_to_coronal_memory/threads_per_job + 1))

	echo "Job Name: ${job_name}"
	echo "Memory Per Thread: ${memory_per_thread}"
	export qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -p ${priority} $reslice_bash_script`

	source $wait_for_jobs_to_complete_script

fi


if [ $input_orientation = "coronal" ];
then

	# Rotate

	export input_image_path=$output_image_path
	export output_image_path="${obc_inpath}fused_coronal_${obc_res_x}x${obc_res_z}x${obc_res_y}.tif"

	if [ ! -f $output_image_path ];
	then

		echo ""
		echo "Rotate...."
		echo ""

		export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
		export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1024/1024/1024" | bc -l)
		export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

		echo "Fused Image Size: ${fused_image_size_bytes} bytes"
		echo "Fused Image Size: ${fused_image_size_gb} GB"
		echo "Fused Image Size (rounded up): ${fused_image_size} GB"

		export oblique_to_coronal_memory=$((fused_image_size*3))
		echo "Oblique to Coronal Memory (safe upper bound): ${oblique_to_coronal_memory} GB"

		# update memory and threads for imagej
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$oblique_to_coronal_memory?$imagej_threads"	

		export job_name="obc_rotate_${obc_res_z}um"
		export memory_per_thread=$((oblique_to_coronal_memory/threads_per_job + 1))

		echo "Job Name: ${job_name}"
		echo "Memory Per Thread: ${memory_per_thread}"
		export qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -p ${priority} $rotate_bash_script`

		source $wait_for_jobs_to_complete_script

	fi


	# Reslice...

	export input_image_path=$output_image_path
	export output_image_path="${obc_inpath}fused_transverse_${obc_res_x}x${obc_res_y}x${obc_res_z}.tif"
	export flip=false
	export direction="Top"

	if [ ! -f $output_image_path ];
	then

		echo ""
		echo "Reslice...."
		echo ""

		export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
		export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1024/1024/1024" | bc -l)
		export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

		echo "Fused Image Size: ${fused_image_size_bytes} bytes"
		echo "Fused Image Size: ${fused_image_size_gb} GB"
		echo "Fused Image Size (rounded up): ${fused_image_size} GB"

		export oblique_to_coronal_memory=$((fused_image_size*3))
		echo "Oblique to Coronal Memory (safe upper bound): ${oblique_to_coronal_memory} GB"

		# update memory and threads for imagej
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$oblique_to_coronal_memory?$imagej_threads"	

		export job_name="obc_reslice_${obc_res_z}um"
		export memory_per_thread=$((oblique_to_coronal_memory/threads_per_job + 1))

		echo "Job Name: ${job_name}"
		echo "Memory Per Thread: ${memory_per_thread}"
		export qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -p ${priority} $reslice_bash_script`

		source $wait_for_jobs_to_complete_script
	fi

fi


# Crop Sagittal

export input_image_path="${obc_inpath}fused_sagittal_${obc_res_y}x${obc_res_z}x${obc_res_x}.tif"
export output_image_path="${obc_inpath}fused_sagittal_${obc_res_y}x${obc_res_z}x${obc_res_x}_CROPPED.tif"
export crop_out_path=${obc_inpath}
export crop_res_x=${obc_res_y}
export crop_res_y=${obc_res_z}
export crop_res_z=${obc_res_x}

if [ ! -f $output_image_path ];
then

	echo ""
	echo "Crop Sagittal...."
	echo ""

	export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
	export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1024/1024/1024" | bc -l)
	export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

	echo "Fused Image Size: ${fused_image_size_bytes} bytes"
	echo "Fused Image Size: ${fused_image_size_gb} GB"
	echo "Fused Image Size (rounded up): ${fused_image_size} GB"

	export crop_memory=$((fused_image_size*2))
	echo "Cropping Memory (safe upper bound): ${crop_memory} GB"

	# update memory and threads for imagej
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$crop_memory?$imagej_threads"	

	export job_name="crop_sagittal_${obc_res_z}um"
	export memory_per_thread=$((crop_memory/threads_per_job + 1))

	echo "Job Name: ${job_name}"
	echo "Memory Per Thread: ${memory_per_thread}"
	qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -p ${priority} $crop_bash_script

fi

if [ $input_orientation = "coronal" ];
then


	# Crop Coronal

	export input_image_path="${obc_inpath}fused_coronal_${obc_res_x}x${obc_res_z}x${obc_res_y}.tif"
	export output_image_path="${obc_inpath}fused_coronal_${obc_res_x}x${obc_res_z}x${obc_res_y}_CROPPED.tif"
	export crop_out_path=${obc_inpath}
	export crop_res_x=${obc_res_x}
	export crop_res_y=${obc_res_z}
	export crop_res_z=${obc_res_y}

	if [ ! -f $output_image_path ];
	then

		echo ""
		echo "Crop Coronal...."
		echo ""

		export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
		export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1024/1024/1024" | bc -l)
		export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

		echo "Fused Image Size: ${fused_image_size_bytes} bytes"
		echo "Fused Image Size: ${fused_image_size_gb} GB"
		echo "Fused Image Size (rounded up): ${fused_image_size} GB"

		export crop_memory=$((fused_image_size*2))
		echo "Cropping Memory (safe upper bound): ${crop_memory} GB"

		# update memory and threads for imagej
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$crop_memory?$imagej_threads"	

		export job_name="crop_coronal_${obc_res_z}um"
		export memory_per_thread=$((crop_memory/threads_per_job + 1))

		echo "Job Name: ${job_name}"
		echo "Memory Per Thread: ${memory_per_thread}"
		qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -p ${priority} $crop_bash_script

	fi

	# Crop Transverse

	export input_image_path="${obc_inpath}fused_transverse_${obc_res_x}x${obc_res_y}x${obc_res_z}.tif"
	export output_image_path="${obc_inpath}fused_transverse_${obc_res_x}x${obc_res_y}x${obc_res_z}_CROPPED.tif"
	export crop_out_path=${obc_inpath}
	export crop_res_x=${obc_res_x}
	export crop_res_y=${obc_res_y}
	export crop_res_z=${obc_res_z}

	if [ ! -f $output_image_path ];
	then

		echo ""
		echo "Crop Transverse..."
		echo ""

		export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
		export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1024/1024/1024" | bc -l)
		export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

		echo "Fused Image Size: ${fused_image_size_bytes} bytes"
		echo "Fused Image Size: ${fused_image_size_gb} GB"
		echo "Fused Image Size (rounded up): ${fused_image_size} GB"

		export crop_memory=$((fused_image_size*2))
		echo "Cropping Memory (safe upper bound): ${crop_memory} GB"

		# update memory and threads for imagej
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$crop_memory?$imagej_threads"	

		export job_name="crop_transverse_${obc_res_z}um"
		export memory_per_thread=$((crop_memory/threads_per_job + 1))

		echo "Job Name: ${job_name}"
		echo "Memory Per Thread: ${memory_per_thread}"
		qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -p ${priority} $crop_bash_script

	fi

fi
