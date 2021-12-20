#!/bin/bash

if [ $start_from_merge = false ];
then

	# wait a few seconds to make sure job will show up in qstat
	sleep 10

	# sleep until the job is no longer in qstat output (jobs are complete)
	qstat_output=`qstat | grep $job_id`

	while [[ "$qstat_output" == *"$job_id"* ]]
	do
	  	sleep 1
		qstat_output=`qstat | grep $job_id` 
	done

fi


# call python script to merge 
python $merge_pairwise_shifts_python_script $data_path $sectioning $num_z_volumes

if [ $estimate_overlaps = true  ];
then

	echo "Estimate Overlaps To Place On Grid..."

	python $estimate_overlaps_python_script $data_path $sectioning $x_overlap_center $x_overlap_delta $y_overlap_center $y_overlap_delta 

fi



