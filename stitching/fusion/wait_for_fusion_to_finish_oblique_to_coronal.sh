#!/bin/bash

# wait a few seconds to make sure job will show up in qstat
sleep 20

# sleep until the job is no longer in qstat output (jobs are complete)
qstat_output=`qstat | grep $job_id`

while [[ "$qstat_output" == *"$job_id"* ]]
do
  	sleep 1
	qstat_output=`qstat | grep $job_id` 
done


# run oblique to coronal isotropic transformations

export job_name_oblique_to_coronal=oblique_to_coronal_isotropic_"$downsampling"
export memory_per_thread=$((fused_image_size/threads_per_job + 1))

echo "Job Name: $job_name_oblique_to_coronal"

# update memory and threads for imagej
# need to allocate memory for processing of full fused image
$imagej_exe --headless --console -macro $update_imagej_memory_macro "$fused_image_size?$imagej_threads"

# send jobs to cluster to merge volumes and oblique to coronal
qsub -N $job_name_oblique_to_coronal -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free=$((memory_per_thread*2))G $oblique_to_coronal_iso_bash_script


# run oblique to coronal full res transformations
if [ $full_res_transformations == true ];
then

	export job_name_oblique_to_coronal=oblique_to_coronal_full_res_"$downsampling"
	export memory_per_thread=$((memory_full_res_transformations/threads_per_job + 1))

	echo "Job Name: $job_name_oblique_to_coronal"

	# update memory and threads for imagej
	# need to allocate memory for processing of full fused image
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$memory_full_res_transformations?$imagej_threads"

	# send jobs to cluster to merge volumes and oblique to coronal
	qsub -N $job_name_oblique_to_coronal -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free=$((memory_per_thread*2))G $oblique_to_coronal_full_res_bash_script


fi
