#!/bin/bash

# This is the main script to run for calculating pairwise shifts

####################################
######## For User to Modify ########
####################################

export data_path=/grid/osten/data_norepl/qi/data/AVP/AVP-IHC-A2/downsample2/

export downsample_x=4
export downsample_y=4
export downsample_z=2

export estimate_overlaps=true

export memory_per_job=40
export threads_per_job=10

export sectioning=false

export start_from_merge=false

export parallel=true

#####################################
#####################################
#####################################

#make sure .n5 exists
if [ ! -d ${data_path}dataset.n5 ]; then
  
	echo ""
	echo "#####"
	echo "Error"
	echo "#####"
	echo ""
	echo "dataset.n5 does not exist..."
	echo ""

	exit
fi


# get current directory
export cur_dir=`pwd`"/"

# get stitching base directory
export base_dir=$(dirname $0)/../../

# set up script paths
export pairwise_shifts_script="${base_dir}stitching/pairwise_shifts/pairwise_shifts.sh"
export pairwise_shifts_macro="${base_dir}stitching/pairwise_shifts/pairwise_shifts.ijm"
export merge_pairwise_shifts_bash_script="${base_dir}stitching/pairwise_shifts/merge_pairwise_shifts.sh"
export merge_pairwise_shifts_python_script="${base_dir}stitching/pairwise_shifts/merge_pairwise_shifts.py"
export get_tile_dimension_python_script="${base_dir}stitching/pairwise_shifts/get_tile_dimension.py"
export estimate_overlaps_python_script="${base_dir}stitching/pairwise_shifts/estimate_overlaps.py"

# import parameters
source "${base_dir}stitching/stitching_params.sh"

# figure out if running on cluster and export paths
is_running_on_cluster $HOSTNAME

# check if overlap range file provided
overlap_range_path="${in_path}overlap_range.txt"
if [ ! -f $overlap_range_path ];then
	echo "Error: overlap_range.txt does not exist"
fi

# read in overlap 
x_overlap_line=`sed -n '1p' $overlap_range_path`
export x_overlap_center=`echo $x_overlap_line | head -n1 | awk '{print $1;}'`
export x_overlap_delta=`echo $x_overlap_line | head -n1 | awk '{print $2;}'`

y_overlap_line=`sed -n '2p' $overlap_range_path`
export y_overlap_center=`echo $y_overlap_line | head -n1 | awk '{print $1;}'`
export y_overlap_delta=`echo $y_overlap_line | head -n1 | awk '{print $2;}'`


# set up paths
export out_path="${data_path}/pairwise_shifts/"
export out_path_logs="${data_path}/pairwise_shifts/logs/"
mkdir -p $out_path $out_path_logs

# copy fiji
cp -r $fiji_path $out_path
export imagej_exe=${out_path}Fiji.app/ImageJ-linux64
chmod +x $imagej_exe

# get dimensions
export num_z_volumes=$(python ${get_tile_dimension_python_script} ${data_path}translate_to_grid.xml z)
export num_y_volumes=$(python ${get_tile_dimension_python_script} ${data_path}translate_to_grid.xml y)

echo ""
echo "##########################"
echo "Calculate Pairwise Shifts"
echo "##########################"
echo ""
echo "Data Path: ${data_path}"
echo "Downsampling: ${downsample_x},${downsample_y},${downsample_z}"
echo "# Z Volumes: ${num_z_volumes}"
echo "Estimate Overlaps: $estimate_overlaps"
echo ""


echo "Write Parameters..."
echo "" >> "${out_path}params.txt"
echo "Data Path: $data_path" >> "${out_path}params.txt"
echo "" >> "${out_path}params.txt"
echo "Downsample X: $downsample_x" >> "${out_path}params.txt"
echo "Downsample Y: $downsample_y" >> "${out_path}params.txt"
echo "Downsample Z: $downsample_z" >> "${out_path}params.txt"
echo "Estimate Overlaps: $estimate_overlaps" >> "${out_path}params.txt"
echo ""


if [ $cluster = true ];
then

	# if only 1 z volume then dont perform in parallel
	if [ $num_z_volumes -eq 1 -o $parallel = false ];
	then
	
		echo "Not running in parallel"

		# memory per thread
		export memory_per_thread=$((memory_per_job/threads_per_job+1))
	
		echo "# Jobs: 1"
		echo "Memory per Job: ${memory_per_job}G"
		echo "# Threads per Job: ${threads_per_job}"
		echo "Memory per Thread: ${memory_per_thread}G"
		echo ""

		# update memory and threads for imagej
	 	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$memory_per_job?$imagej_threads"
	
		# run pairwise shifts in parallel on cluster
		qsub -N pairwise_shifts -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free=$((2*memory_per_thread)) $pairwise_shifts_script

	else


		# number of jobs is one less than z
		export num_jobs=$((num_z_volumes-1))	

		# memory per thread
		export memory_per_thread=$((memory_per_job/threads_per_job+1))
	
		echo "# Jobs: ${num_jobs}"
		echo "Memory per Job: ${memory_per_job}G"
		echo "# Threads per Job: ${threads_per_job}"
		echo "Memory per Thread: ${memory_per_thread}G"
		echo ""

		if [ $start_from_merge = true ];
		then
			nohup $merge_pairwise_shifts_bash_script > "${out_path_logs}nohup_merge_pairwise_shifts.out" &
			exit
		fi

		# create folders for each job
		for (( i=1; i<$((num_z_volumes)); i++ ))
		do  
			job_path="${out_path}Z_${i}_"$((i+1))/
		
			mkdir $job_path
			cp "${data_path}translate_to_grid.xml" $job_path
			sed -i 's/dataset/\.\.\/\.\.\/dataset/'  ${job_path}translate_to_grid.xml
		done


		# update memory and threads for imagej
	 	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$memory_per_job?$imagej_threads"
	
		# run pairwise shifts in parallel on cluster
		qsub_output=`qsub -N pairwise_shifts -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free=$((2*memory_per_thread)) -t 1-$num_jobs $pairwise_shifts_script`

		# parse qsub output to get job id
		export job_id=`echo $qsub_output | awk 'match($0,/[0-9]+/){print substr($0, RSTART, RLENGTH)}'`

		# call merge shift bash script to wait until all jobs are done
		# use nohup and run in background so if terminal is closed, script will persist
		nohup $merge_pairwise_shifts_bash_script > "${out_path_logs}nohup_merge_pairwise_shifts.out" &

	fi

else
	
	echo "Need to Develop - pairwise stitching not parallel and not on cluster!!!"

fi




