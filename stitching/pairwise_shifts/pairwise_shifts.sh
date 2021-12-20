#!/bin/bash

echo ""
echo "########################################"
echo "Calculate Pairwise Shifts (Bash Script)"
echo "#########################################"
echo ""

# move log files
mv "${cur_dir}pairwise_shifts."*${JOB_ID}* $out_path_logs


# calculate pairwise shifts
if [ $num_z_volumes -eq 1 ];
then

	# run pairwise shifts
	$imagej_exe --headless --console -macro $pairwise_shifts_macro "${data_path}?${downsample_x}?${downsample_y}?${downsample_z}?${num_z_volumes}?0?${num_y_volumes}"

	# rename files
	mv ${data_path}translate_to_grid.xml ${data_path}pairwise_shifts.xml
	mv ${data_path}translate_to_grid.xml~1 ${data_path}translate_to_grid.xml


	if [ $estimate_overlaps = true  ];
	then

		echo "Estimate Overlaps To Place On Grid..."

		python $estimate_overlaps_python_script $data_path $sectioning $x_overlap_center $x_overlap_delta $y_overlap_center $y_overlap_delta 

	fi
else

	job_folder="${out_path}Z_${SGE_TASK_ID}_$((SGE_TASK_ID+1))/"

	# run pairwise shifts
	$imagej_exe --headless --console -macro $pairwise_shifts_macro "${job_folder}?${downsample_x}?${downsample_y}?${downsample_z}?${num_z_volumes}?${SGE_TASK_ID}?${num_y_volumes}"
fi









