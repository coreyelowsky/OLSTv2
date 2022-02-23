#!/bin/bash

echo ""
echo "######"
echo "Fusion"
echo "######"
echo ""

# make sure input path ends in /
if [[ ! $input_data_path == */ ]];
then
	input_data_path="${input_data_path}/"
fi

# make sure priority is <=0
if [ $priority -gt 0 ];
then

	echo "Error: priority must be less than or equal to 0"
	exit
fi

# if copmuting isotropic from full res then 
# must merge full res image
if [ $compute_isotropic_from_full_res = true ];
then
	merge_full_res_fused_image=true
fi

# get current directory
export cur_dir=`pwd`"/"

# get base directory
export base_dir=$(dirname $0)/../../

# set up script paths
export define_bounding_boxes_script="$base_dir"stitching/fusion/define_bounding_boxes.py
export fusion_script="$base_dir"stitching/fusion/fusion.sh
export fusion_macro="$base_dir"stitching/fusion/fusion.ijm
export process_fusion_script="$base_dir"stitching/fusion/process_fusion.sh
export merge_fused_volumes_bash_script="$base_dir"stitching/fusion/merge_fused_volumes.sh
export merge_fused_volumes_python_script="$base_dir"stitching/fusion/merge_fused_volumes.py
export oblique_to_coronal_bash_script="$base_dir"stitching/fusion/oblique_to_coronal.sh
export crop_python_script="$base_dir"stitching/oblique_to_coronal/crop_fused_image.py
export crop_bash_script="$base_dir"stitching/oblique_to_coronal/crop_fused_image.sh
export define_bounding_box_macro="$base_dir"stitching/fusion/define_bounding_box.ijm
export downsample_script="$base_dir"stitching/fusion/downsample.sh
export downsample_macro="$base_dir"stitching/fusion/downsample.ijm
export reslice_bash_script="$base_dir"stitching/oblique_to_coronal/reslice.sh
export reslice_macro="$base_dir"stitching/oblique_to_coronal/reslice.ijm
export shear_bash_script="$base_dir"stitching/oblique_to_coronal/shear.sh
export shear_macro="$base_dir"stitching/oblique_to_coronal/shear.ijm
export rotate_bash_script="$base_dir"stitching/oblique_to_coronal/rotate.sh
export rotate_macro="$base_dir"stitching/oblique_to_coronal/rotate.ijm
export fusion_local_machine_script="$base_dir"stitching/fusion/fusion_local_machine.sh

# import parameters
source "$base_dir"stitching/stitching_params.sh

# figure out if running on cluster and export paths
is_running_on_cluster $HOSTNAME

# calculate and format output resolution 
voxel_size_string=`grep 'Voxel Size' ${input_data_path}translate_to_grid.txt`
voxel_size_extracted=`echo $voxel_size_string | grep -Eo '[+-]?[0-9]+([.][0-9]+)?'`
voxel_size_array=($voxel_size_extracted)
export res_x=${voxel_size_array[0]}
export res_y=${voxel_size_array[1]}
export res_z=${voxel_size_array[2]}

# calculate how much to downsample in z
# remove trailing zeros
export downsampling=`echo $out_res_z/$res_z|bc -l`
downsampling=$(echo ${downsampling}  | sed '/\./ s/\.\{0,1\}0\{1,\}$//')

# rules for resolution name is first convert to float with 2 decimals
# and then remove trailing zeros
export out_res_x=$(echo "$res_x * $downsampling" | bc -l | xargs printf "%.2f" | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
export out_res_y=$(echo "$res_y * $downsampling" | bc -l | xargs printf "%.2f" | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
export out_res=$out_res_x"x"$out_res_y"x"$out_res_z
export out_res_isotropic=$out_res_z"x"$out_res_z"x"$out_res_z

echo ""
echo "Input Data Path: $input_data_path"
echo "XML Filename: $xml_file_name"
echo "Downsampling: $downsampling"
echo "Input Orientation: ${input_orientation}"
echo "Oblique -> Coronal: $oblique_to_coronal_isotropic"
echo "Oblique -> Coronal (full res): $oblique_to_coronal_full_res"
echo "Output Resolution: $out_res"
echo "Output Resolution (isotropic): $out_res_isotropic"
echo "Fusion Memory: $fusion_memory"G
echo "Threads Per Job: $threads_per_job"
echo ""

# create output directory
# if only fusing a region then will be included in directory name
if [ $fuse_region = true ];
then
	export region_id="region_z${z_min}-${z_max}_y${y_min}-${y_max}"
	export output_data_path="${input_data_path}brute_force_fusions/fusion_${out_res_z}um_${region_id}_${xml_file_name}/"
else
	export output_data_path="${input_data_path}brute_force_fusions/fusion_${out_res_z}um_${xml_file_name}/"
fi

# make output directories
export log_path="${output_data_path}logs/"
export isotropic_path="${output_data_path}isotropic/"
export full_res_path="${output_data_path}full_res/"
mkdir -p $output_data_path $log_path $isotropic_path $full_res_path

# copy fiji (always recopy even if it exists already)
export imagej_exe=${output_data_path}Fiji.app/ImageJ-linux64
if [ ! -f $imagej_exe ];
then 
	echo "Copying Fiji..."
	cp -r $fiji_path $output_data_path
	chmod +x $imagej_exe
fi
echo "ImageJ Path: ${imagej_exe}"


# if running on cluster check if parallel or not
if [ $cluster = true ];
then

	echo "Load Modules to use correct python version...."
	module load EBModules
	module load Python/3.8.6-GCCcore-10.2.0

	if [ $parallel = true ];
	then
		
		echo ""
		echo "Running in parallel..."
		echo ""

		export num_jobs=$((grid_size*grid_size))
		echo "# Parallel Jobs: $num_jobs"
		echo "Grid Size:" "$grid_size"x"$grid_size"


		# if any skip processing flags are true then go straight to next script and exit
		if [ $start_from_downsample = true -o $start_from_merge = true -o $start_from_oblique_to_coronal = true ];
		then
			echo ""
			nohup $process_fusion_script > "${log_path}process_fusion.txt" &
			exit
		fi

		echo ""
		echo "Write Parameters..."
		echo "" >> "$output_data_path"params_fusion.txt
		echo "Input Data Path: $output_data_path" >> "$output_data_path"params_fusion.txt
		echo "XML Filename: $xml_file_name" >> "$output_data_path"params_fusion.txt
		echo "Grid Size:" "$grid_size"x"$grid_size" >> "$output_data_path"params_fusion.txt
		echo "Downsampling: $downsampling" >> "$output_data_path"params_fusion.txt
		echo "Pixel Type: $pixel_type" >> "$output_data_path"params_fusion.txt
		echo "Interpolation: $interpolation" >> "$output_data_path"params_fusion.txt
		echo "blend: $blend" >> "$output_data_path"params_fusion.txt
		echo "" >> "$output_data_path"params_fusion.txt
		echo ""

		# run python script to create bounding boxes and save xml
		python $define_bounding_boxes_script ${input_data_path}brute_force_xmls ${xml_file_name}.xml $grid_size $downsampling $output_data_path $fuse_region $z_min $z_max $y_min $y_max
		

		export xml_full_path="${output_data_path}${xml_file_name}_bboxes_${grid_size}.xml"
		echo ""

		# update memory and threads for imagej
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$fusion_memory?$imagej_threads"

		# run fusion jobs on cluster
		export job_name_fusion="fusion_${out_res_z}um"
		export memory_per_thread_fusion=$((fusion_memory/threads_per_job+1))
		export fusion_out_path=${output_data_path}full_res/
		
		echo "Job Name: ${job_name_fusion}"
		echo "Memory per Thread: ${memory_per_thread_fusion}G"
		export qsub_output=`qsub -N $job_name_fusion -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread_fusion*2))"G -t 1-$num_jobs -p ${priority} $fusion_script`

		# call merge volumes bash script to wait until all jobs are done
		# use nohup and run in background so if terminal is closed, script will persist
		echo "Wait for all fused volumes to complete and then process fusions..."
		echo ""

		nohup $process_fusion_script > "${log_path}process_fusion.txt" &
	
	else

		echo ""
		echo "#######################"
		echo "Not Running in parallel"
		echo "#######################"
		echo ""

		echo "Need to develop..."

	fi

else
	
	echo ""
	echo "######################"
	echo "Not Running on Cluster"
	echo "######################"
	echo ""

	nohup $fusion_local_machine_script > "${log_path}fusion_logs.txt" &

fi

