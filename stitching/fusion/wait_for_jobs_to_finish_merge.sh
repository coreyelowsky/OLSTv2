#!/bin/bash

echo ""
echo "#################################"
echo "Wait For Jobs to Finish and Merge"
echo "#################################"
echo ""


if [ $start_from_merge = false -a $start_from_oblique_to_coronal = false ];
then
	
	echo "waiting for jobs to finish...."
	echo ""

	# wait a few seconds to make sure job will show up in qstat
	sleep 20

	# sleep until the job is no longer in qstat output (jobs are complete)
	qstat_output=`qstat | grep $job_id`

	while [[ "$qstat_output" == *"$job_id"* ]]
	do
	 	sleep 1
		qstat_output=`qstat | grep $job_id` 
	done
		
	echo "all jobs finished..."

fi



# calculate fused image size
export fused_image_size_bytes=`du -bc ${output_data_path}*.tif | tail -1 | sed -e 's/\s.*$//'`
export fused_image_size_gb=$(echo "$fused_image_size_bytes/1000/1000/1000" | bc -l)
export fused_image_size=`python -c "from math import ceil; print(ceil($fused_image_size_gb))"`

echo "Fused Image Size: ${fused_image_size_bytes} bytes"
echo "Fused Image Size: ${fused_image_size_gb} GB"
echo "Fused Image Size (rounded up): ${fused_image_size} GB"

export fused_image_size=$((fused_image_size*2))
export memory_full_res_transformations=$((fused_image_size*6))

echo "Fused Image Size (gb - isotropic - safe upper bound): ${fused_image_size}"

export job_name_merge=merge_fusion_"${out_res_z}"um
export memory_per_thread=$((fused_image_size/threads_per_job + 1))

echo "Job Name: $job_name_merge"

# update memory and threads for imagej
# need to allocate memory for processing of full fused image
$imagej_exe --headless --console -macro $update_imagej_memory_macro "$fused_image_size?$imagej_threads"

# send jobs to cluster to merge volumes and oblique to coronal
qsub_output=`qsub -N $job_name_merge -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $merge_fused_volumes_bash_script`

# if computing full resolution images, need to wait for merge to complete
# needed to organize this way to update imagej memory
# otherwise the fusion would be constrained by much larger memory requirements than necessary
if [ $full_res_transformations == true ];
then

	# parse qsub output to get job id
	export job_id=`echo $qsub_output | awk 'match($0,/[0-9]+/){print substr($0, RSTART, RLENGTH)}'`
	echo "Job ID: $job_id"
	echo ""

	# wait a few seconds to make sure job will show up in qstat
	sleep 20

	# sleep until the job is no longer in qstat output (jobs are complete)
	qstat_output=`qstat | grep $job_id`

	while [[ "$qstat_output" == *"$job_id"* ]]
	do
	  	sleep 1
		qstat_output=`qstat | grep $job_id` 
	done


	export job_name_oblique_to_coronal_full_res=oblique_to_coronal_full_res_"$downsampling"
	export memory_per_thread=$((memory_full_res_transformations/threads_per_job + 1))

	echo "Job Name: $job_name_oblique_to_coronal_full_res"

	# update memory and threads for imagej
	# need to allocate memory for processing of full fused image
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$memory_full_res_transformations?$imagej_threads"

	# send jobs to cluster to merge volumes and oblique to coronal
	qsub -N $job_name_oblique_to_coronal_full_res -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread*2))"G $oblique_to_coronal_full_res_bash_script


fi



