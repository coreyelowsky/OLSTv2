#!/bin/bash

echo ""
echo "##############"
echo "Process Fusion"
echo "##############"
echo ""

# WAIT FOR FUSIONS TO FINISH BEFORE MERGING
# DONT NEED TO WAIT IF STARTING FROM NEXT STEPS
if [ $start_from_downsample = false -a $start_from_merge = false -a $start_from_oblique_to_coronal = false ];
then	
	source $wait_for_jobs_to_complete_script
fi

# MERGE FUSED VOLUMES
# IF STARTING FROM OBLIQUE TO CORONAL THEN DONT NEED THIS
if [ $start_from_oblique_to_coronal = false ];
then

	# if want to save full res then save here
	if [ $merge_full_res_fused_image = true ];
	then 

		echo ""
		echo "##########################"
		echo "Merge Full Res Fused image"
		echo "##########################"
		echo ""

		# calculate memory size for fusion
		export fused_image_size_bytes=`du -bc ${full_res_path}*.tif | tail -1 | sed -e 's/\s.*$//'`
		export fused_image_size_gb=$(echo "$fused_image_size_bytes/1000/1000/1000" | bc -l)
		export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

		echo "Fused Image Size: ${fused_image_size_bytes} bytes"
		echo "Fused Image Size: ${fused_image_size_gb} GB"
		echo "Fused Image Size (rounded up): ${fused_image_size} GB"

		# update memory and threads for imagej
		# need to allocate memory for processing of full fused image
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$fused_image_size?$imagej_threads"
	
		# set up env variables for merge
		export merge_in_path=${output_data_path}
		export merge_out_path="${output_data_path}full_res"
		export merge_out_res=${out_res}

		# send jobs to cluster to merge volumes
		export job_name_merge=merge_fusion_"${out_res_z}"um_full_res
		export memory_per_thread=$((fused_image_size/threads_per_job + 1))

		echo "Job Name: $job_name_merge"
		echo "Memory Per Thread: ${memory_per_thread}"
		export qsub_output=`qsub -N $job_name_merge -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $merge_fused_volumes_bash_script`

		source $wait_for_jobs_to_complete_script

		

	fi

	# DOWNSAMPLE
	if [ $start_from_merge = false ];
	then
	
		echo ""
		echo "###################################"
		echo "Downsample Fused Images in Parallel"
		echo "###################################"
		echo ""


		# calculate fused image size
		export fused_image_size_bytes=`du -bc ${full_res_path}fused_1.tif | tail -1 | sed -e 's/\s.*$//'`
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

		# send jobs to cluster to merge volumes
		export job_name_downsample="downsample_${out_res_z}um"
		export memory_per_thread=$((downsample_memory/threads_per_job + 1))
		echo "Job Name: ${job_name_downsample}"
		echo "Memory Per Thread: ${memory_per_thread}"
		export qsub_output=`qsub -N $job_name_downsample -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -t 1-$num_jobs $downsample_script`

		source $wait_for_jobs_to_complete_script

	fi

	echo ""
	echo "#####"
	echo "Merge"
	echo "#####"
	echo ""

	# calculate fused image size
	export fused_image_size_bytes=`du -bc ${isotropic_path}*.tif | tail -1 | sed -e 's/\s.*$//'`
	export fused_image_size_gb=$(echo "$fused_image_size_bytes/1000/1000/1000" | bc -l)
	export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

	echo "Fused Image Size: ${fused_image_size_bytes} bytes"
	echo "Fused Image Size: ${fused_image_size_gb} GB"
	echo "Fused Image Size (rounded up): ${fused_image_size} GB"

	# update memory and threads for imagej
	# need to allocate memory for processing of full fused image
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$fused_image_size?$imagej_threads"

	# set up env variables for merge
	export merge_in_path="${output_data_path}isotropic"
	export merge_out_path="${output_data_path}isotropic"
	export merge_out_res=${out_res_isotropic}

	export job_name_merge=merge_fusion_"${out_res_z}"um
	export memory_per_thread=$((fused_image_size/threads_per_job + 1))
	echo "Job Name: ${job_name_merge}"
	echo "Memory Per Thread: ${memory_per_thread}"

	# send jobs to cluster to merge volumes
	export qsub_output=`qsub -N $job_name_merge -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $merge_fused_volumes_bash_script`

	source $wait_for_jobs_to_complete_script

fi

# OBLIQUE TO CORONAL FOR ISOTROPIC
# FOR BETTER MEMORY MANAGEMENT RUN EACH STEP SEPARATELY
if [ $oblique_to_coronal = true ]
then

	echo ""
	echo "##################"
	echo "Oblique to Coronal"
	echo "##################"
	echo ""


	echo ""
	echo "Reslice + Vertical Flip...."
	echo ""

	# get size of image
	export input_image_path="${isotropic_path}fused_oblique_${out_res_z}x${out_res_z}x${out_res_z}.tif"
	export output_image_path="${isotropic_path}fused_oblique_resliced_${out_res_z}x${out_res_z}x${out_res_z}.tif"
	export flip=true
	export direction="Left"

	if [ ! -f $input_image_path ];
	then
		echo "Error: Image Does Not Exit - ${input_image_path}"
		exit
	fi

	if [ ! -f $output_image_path ];
	then

		export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
		export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1000/1000/1000" | bc -l)
		export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`
	
		echo "Fused Image Size: ${fused_image_size_bytes} bytes"
		echo "Fused Image Size: ${fused_image_size_gb} GB"
		echo "Fused Image Size (rounded up): ${fused_image_size} GB"

		export oblique_to_coronal_memory=$((fused_image_size*3))
		echo "Oblique to Coronal Memory (safe upper bound): ${oblique_to_coronal_memory} GB"

		# update memory and threads for imagej
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$oblique_to_coronal_memory?$imagej_threads"	

		export job_name="obc_reslice_vert_${out_res_z}um"
		export memory_per_thread=$((oblique_to_coronal_memory/threads_per_job + 1))

		echo "Job Name: ${job_name}"
		echo "Memory Per Thread: ${memory_per_thread}"
		export qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $reslice_bash_script`

		source $wait_for_jobs_to_complete_script

	fi

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

	if [ ! -f $output_image_path ];
	then

		export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
		export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1000/1000/1000" | bc -l)
		export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`
	
		echo "Fused Image Size: ${fused_image_size_bytes} bytes"
		echo "Fused Image Size: ${fused_image_size_gb} GB"
		echo "Fused Image Size (rounded up): ${fused_image_size} GB"

		export oblique_to_coronal_memory=$((fused_image_size*3))
		echo "Oblique to Coronal Memory (safe upper bound): ${oblique_to_coronal_memory} GB"

		# update memory and threads for imagej
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$oblique_to_coronal_memory?$imagej_threads"	

		export job_name="obc_shear_${out_res_z}um"
		export memory_per_thread=$((oblique_to_coronal_memory/threads_per_job + 1))

		echo "Job Name: ${job_name}"
		echo "Memory Per Thread: ${memory_per_thread}"
		export qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $shear_bash_script`

		source $wait_for_jobs_to_complete_script

	fi

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

	if [ ! -f $output_image_path ];
	then

		export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
		export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1000/1000/1000" | bc -l)
		export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`
	
		echo "Fused Image Size: ${fused_image_size_bytes} bytes"
		echo "Fused Image Size: ${fused_image_size_gb} GB"
		echo "Fused Image Size (rounded up): ${fused_image_size} GB"

		export oblique_to_coronal_memory=$((fused_image_size*3))
		echo "Oblique to Coronal Memory (safe upper bound): ${oblique_to_coronal_memory} GB"

		# update memory and threads for imagej
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$oblique_to_coronal_memory?$imagej_threads"	

		export job_name="obc_reslice_${out_res_z}um"
		export memory_per_thread=$((oblique_to_coronal_memory/threads_per_job + 1))

		echo "Job Name: ${job_name}"
		echo "Memory Per Thread: ${memory_per_thread}"
		export qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $reslice_bash_script`

		source $wait_for_jobs_to_complete_script
	
	fi


	if [ $input_orientation = "coronal" ];
	then

		echo ""
		echo "Rotate...."
		echo ""

		export input_image_path=$output_image_path
		export output_image_path="${isotropic_path}fused_coronal_${out_res_z}x${out_res_z}x${out_res_z}.tif"

		if [ ! -f $output_image_path ];
		then

			export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
			export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1000/1000/1000" | bc -l)
			export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`
	
			echo "Fused Image Size: ${fused_image_size_bytes} bytes"
			echo "Fused Image Size: ${fused_image_size_gb} GB"
			echo "Fused Image Size (rounded up): ${fused_image_size} GB"

			export oblique_to_coronal_memory=$((fused_image_size*3))
			echo "Oblique to Coronal Memory (safe upper bound): ${oblique_to_coronal_memory} GB"

			# update memory and threads for imagej
			$imagej_exe --headless --console -macro $update_imagej_memory_macro "$oblique_to_coronal_memory?$imagej_threads"	

			export job_name="obc_rotate_${out_res_z}um"
			export memory_per_thread=$((oblique_to_coronal_memory/threads_per_job + 1))

			echo "Job Name: ${job_name}"
			echo "Memory Per Thread: ${memory_per_thread}"
			export qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $rotate_bash_script`

			source $wait_for_jobs_to_complete_script

		fi

		echo ""
		echo "Reslice...."
		echo ""

		export input_image_path=$output_image_path
		export output_image_path="${isotropic_path}fused_transverse_${out_res_z}x${out_res_z}x${out_res_z}.tif"
		export flip=false
		export direction="Top"

		if [ ! -f $output_image_path ];
		then

			export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
			export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1000/1000/1000" | bc -l)
			export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`
	
			echo "Fused Image Size: ${fused_image_size_bytes} bytes"
			echo "Fused Image Size: ${fused_image_size_gb} GB"
			echo "Fused Image Size (rounded up): ${fused_image_size} GB"

			export oblique_to_coronal_memory=$((fused_image_size*3))
			echo "Oblique to Coronal Memory (safe upper bound): ${oblique_to_coronal_memory} GB"

			# update memory and threads for imagej
			$imagej_exe --headless --console -macro $update_imagej_memory_macro "$oblique_to_coronal_memory?$imagej_threads"	

			export job_name="obc_reslice_${out_res_z}um"
			export memory_per_thread=$((oblique_to_coronal_memory/threads_per_job + 1))

			echo "Job Name: ${job_name}"
			echo "Memory Per Thread: ${memory_per_thread}"
			export qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $reslice_bash_script`

			source $wait_for_jobs_to_complete_script
		fi

	fi

	echo ""
	echo "Crop Sagittal...."
	echo ""

	export input_image_path="${isotropic_path}fused_sagittal_${out_res_z}x${out_res_z}x${out_res_z}.tif"
	export output_image_path="${isotropic_path}fused_sagittal_${out_res_z}x${out_res_z}x${out_res_z}_CROPPED.tif"
	export crop_out_path=${isotropic_path}
	export crop_res_x=${out_res_z}
	export crop_res_y=${out_res_z}
	export crop_res_z=${out_res_z}

	if [ ! -f $output_image_path ];
	then

		export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
		export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1000/1000/1000" | bc -l)
		export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

		echo "Fused Image Size: ${fused_image_size_bytes} bytes"
		echo "Fused Image Size: ${fused_image_size_gb} GB"
		echo "Fused Image Size (rounded up): ${fused_image_size} GB"

		export crop_memory=$((fused_image_size*2))
		echo "Cropping Memory (safe upper bound): ${crop_memory} GB"

		# update memory and threads for imagej
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$crop_memory?$imagej_threads"	

		export job_name="crop_sagittal_${out_res_z}um"
		export memory_per_thread=$((crop_memory/threads_per_job + 1))

		echo "Job Name: ${job_name}"
		echo "Memory Per Thread: ${memory_per_thread}"
		qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $crop_bash_script

	fi

	if [ $input_orientation = "coronal" ];
	then

		echo ""
		echo "Crop Coronal...."
		echo ""

		export input_image_path="${isotropic_path}fused_coronal_${out_res_z}x${out_res_z}x${out_res_z}.tif"
		export output_image_path="${isotropic_path}fused_coronal_${out_res_z}x${out_res_z}x${out_res_z}_CROPPED.tif"
		export crop_out_path=${isotropic_path}
		export crop_res_x=${out_res_z}
		export crop_res_y=${out_res_z}
		export crop_res_z=${out_res_z}

		if [ ! -f $output_image_path ];
		then

			export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
			export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1000/1000/1000" | bc -l)
			export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

			echo "Fused Image Size: ${fused_image_size_bytes} bytes"
			echo "Fused Image Size: ${fused_image_size_gb} GB"
			echo "Fused Image Size (rounded up): ${fused_image_size} GB"

			export crop_memory=$((fused_image_size*2))
			echo "Cropping Memory (safe upper bound): ${crop_memory} GB"

			# update memory and threads for imagej
			$imagej_exe --headless --console -macro $update_imagej_memory_macro "$crop_memory?$imagej_threads"	

			export job_name="crop_coronal_${out_res_z}um"
			export memory_per_thread=$((crop_memory/threads_per_job + 1))

			echo "Job Name: ${job_name}"
			echo "Memory Per Thread: ${memory_per_thread}"
			qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $crop_bash_script

		fi

		echo ""
		echo "Crop Transverse..."
		echo ""

		export input_image_path="${isotropic_path}fused_transverse_${out_res_z}x${out_res_z}x${out_res_z}.tif"
		export output_image_path="${isotropic_path}fused_transverse_${out_res_z}x${out_res_z}x${out_res_z}_CROPPED.tif"
		export crop_out_path=${isotropic_path}
		export crop_res_x=${out_res_z}
		export crop_res_y=${out_res_z}
		export crop_res_z=${out_res_z}

		if [ ! -f $output_image_path ];
		then

			export fused_image_size_bytes=`du -bc ${input_image_path} | tail -1 | sed -e 's/\s.*$//'`
			export fused_image_size_gb=$(echo "${fused_image_size_bytes}/1000/1000/1000" | bc -l)
			export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

			echo "Fused Image Size: ${fused_image_size_bytes} bytes"
			echo "Fused Image Size: ${fused_image_size_gb} GB"
			echo "Fused Image Size (rounded up): ${fused_image_size} GB"

			export crop_memory=$((fused_image_size*2))
			echo "Cropping Memory (safe upper bound): ${crop_memory} GB"

			# update memory and threads for imagej
			$imagej_exe --headless --console -macro $update_imagej_memory_macro "$crop_memory?$imagej_threads"	

			export job_name="crop_transverse_${out_res_z}um"
			export memory_per_thread=$((crop_memory/threads_per_job + 1))

			echo "Job Name: ${job_name}"
			echo "Memory Per Thread: ${memory_per_thread}"
			qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $crop_bash_script

		fi

	fi

fi



# OBLIQUE TO CORONAL FOR FULL RESOLUTION
if [ $full_res_transformations = true ];
then

	echo ""
	echo "Need to develop full res transformation"
	echo ""

	#export job_name_oblique_to_coronal_full_res=oblique_to_coronal_full_res_"$downsampling"
	#export memory_per_thread=$((memory_full_res_transformations/threads_per_job + 1))

	#echo "Job Name: $job_name_oblique_to_coronal_full_res"

	# update memory and threads for imagej
	# need to allocate memory for processing of full fused image
	#$imagej_exe --headless --console -macro $update_imagej_memory_macro "$memory_full_res_transformations?$imagej_threads"

	# send jobs to cluster to merge volumes and oblique to coronal
	#qsub -N $job_name_oblique_to_coronal_full_res -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $oblique_to_coronal_full_res_bash_script


fi



