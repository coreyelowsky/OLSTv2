#!/bin/bash

echo ""
echo "wait for jobs to complete..."
echo ""

# extract job is from qsub output
export job_id=`echo $qsub_output | awk 'match($0,/[0-9]+/){print substr($0, RSTART, RLENGTH)}'`
echo "Job ID: ${job_id}"

# sleep a few seconds to make sure jobs show up in cluster
sleep 5

# get qstat output
qstat_output=`qstat | grep $job_id`

# loop until job id no longer shows up in qstat output
while [[ "$qstat_output" == *"$job_id"* ]]
do
  	sleep 1
	qstat_output=`qstat | grep $job_id` 
done

echo ""
echo "jobs are complete!"
echo ""
