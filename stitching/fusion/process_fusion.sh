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

	if [ -z "$qsub_output" ];
	then
		echo "ERROR: qsub output is empty"
		exit
	fi

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
		export merge_in_path=${full_res_path}
		export merge_out_path="${full_res_path}"
		export merge_out_res=${out_res}
		export delete_after_merge=false

		# send jobs to cluster to merge volumes
		export job_name_merge=merge_fusion_"${out_res_z}"um_full_res
		export memory_per_thread=$((fused_image_size/threads_per_job + 1))

		echo "Job Name: $job_name_merge"
		echo "Memory Per Thread: ${memory_per_thread}"
		export qsub_output=`qsub -N $job_name_merge -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -p ${priority} $merge_fused_volumes_bash_script`

		source $wait_for_jobs_to_complete_script

		# OBLIQUE TO CORONAL FOR FULL RESOLUTION
		if [ $oblique_to_coronal_full_res = true ];
		then

			echo ""
			echo "####################################"
			echo "Oblique to Coronal (Full Resolution)"
			echo "####################################"
			echo ""

			export obc_inpath=$full_res_path
			export obc_res_x=$out_res_x
			export obc_res_y=$out_res_y
			export obc_res_z=$out_res_z
			
			# run in background so execution continues
			$oblique_to_coronal_bash_script > "${log_path}oblique_to_coronal_full_res.txt" &

		fi


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
		export qsub_output=`qsub -N $job_name_downsample -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -t 1-$num_jobs -p ${priority} $downsample_script`

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
	export merge_in_path="${isotropic_path}"
	export merge_out_path="${isotropic_path}"
	export merge_out_res=${out_res_isotropic}
	export delete_after_merge=true

	export job_name_merge=merge_fusion_"${out_res_z}"um_isotropic
	export memory_per_thread=$((fused_image_size/threads_per_job + 1))
	echo "Job Name: ${job_name_merge}"
	echo "Memory Per Thread: ${memory_per_thread}"

	# send jobs to cluster to merge volumes
	export qsub_output=`qsub -N $job_name_merge -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G -p ${priority} $merge_fused_volumes_bash_script`

	source $wait_for_jobs_to_complete_script

fi

# OBLIQUE TO CORONAL FOR ISOTROPIC
if [ $oblique_to_coronal_isotropic = true ]
then

	echo ""
	echo "##############################"
	echo "Oblique to Coronal (Isotropic)"
	echo "##############################"
	echo ""

	export obc_inpath=$isotropic_path
	export obc_res_x=$out_res_z
	export obc_res_y=$out_res_z
	export obc_res_z=$out_res_z

	# run in background to allow full res jobs to start
	$oblique_to_coronal_bash_script > "${log_path}oblique_to_coronal_isotropic.txt" &
	
fi

# OBLIQUE TO CORONAL FOR FULL RESOLUTION
if [ $oblique_to_coronal_full_res = true -a $start_from_oblique_to_coronal = true ];
then

	echo ""
	echo "####################################"
	echo "Oblique to Coronal (Full Resolution)"
	echo "####################################"
	echo ""

	export obc_inpath=$full_res_path
	export obc_res_x=$out_res_x
	export obc_res_y=$out_res_y
	export obc_res_z=$out_res_z

	$oblique_to_coronal_bash_script > "${log_path}oblique_to_coronal_full_res.txt"

fi


