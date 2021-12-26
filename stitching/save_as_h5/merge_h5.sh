#!/bin/bash

# wait a few seconds to make sure job will show up in qstat
sleep 10

# sleep until the job is no longer in qstat output (jobs are complete)
qstat_output=`qstat | grep $job_id`

while [[ "$qstat_output" == *"$job_id"* ]]
do
  	sleep 1
	qstat_output=`qstat | grep $job_id` 
done

# call python script to merge 
python $merge_h5_python_script $out_path $num_volumes



