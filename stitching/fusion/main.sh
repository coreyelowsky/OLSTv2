#!/bin/bash

# This is the main script to fuse dataset using Big Stitcher

####################################
######## For User to Modify ########
####################################

# input directory
export input_data_path=/grid/osten/data_norepl/qi/data/PV/PV-GFP-M8/

# if true then assumes that grid of fused images have already
# been created and will start at merge step
export start_from_merge=false

# if true then assumes the image has been already fused
# and merged and will start from oblique to coronal
export start_from_oblique_to_coronal=false

# if true will compute full res image, otherwise
# will downsample grid of fused images before merging
# if false will not be able to create full res images (anisotropic)
export compute_full_res_fused_image=false

# output resolution for z
export out_res_z=5

# grid dimensions for parallel fusion
# e.g. if grid_size=2, will be a 2x2 grid -> 4 jobs
export grid_size=10

# xml filename
export xml_file_name=estimate_overlaps.xml

# if only want to fuse a small section then set to true
# otherwise set to false
export fuse_region=false
export z_min=25
export z_max=25
export y_min=19
export y_max=19

# whether to run in parallel or not
# if not running on the cluster this will be ignored
export parallel=true

# output pixel type
export pixel_type="[16-bit unsigned integer]"

# interpolation type
export interpolation="[Linear Interpolation]"

# blending
export blend=true

# whether to run oblique -> coronal trnasformations
# will always do isotopric transformation by default
# will only do full res transformations if specified
export oblique_to_coronal=true
export full_res_transformations=false

# please make either 'coronal' or 'sagittal'
# this is needed for oblique to coronal orientation
export input_orientation=coronal

# memory
export fusion_memory=10

# threads per job
# minumum is 2 since 2 threads corresponds to one physical core (slot)
# each physical slot (core) has 2 logical cores (threads)
export threads_per_job=12

#####################################
#####################################
#####################################

echo ""
echo "######"
echo "Fusion"
echo "######"
echo ""

echo "Load Modules to use correct python...."
module load EBModules
module load Python/3.8.6-GCCcore-10.2.0

# get current directory
export cur_dir=`pwd`"/"

# get base directory
export base_dir=$(dirname $0)/../../

# set up script paths
export define_bounding_boxes_script="$base_dir"stitching/fusion/define_bounding_boxes.py
export merge_fused_volumes_bash_script="$base_dir"stitching/fusion/merge_fused_volumes.sh
export merge_fused_volumes_python_script="$base_dir"stitching/fusion/merge_fused_volumes.py
export fusion_parallel_script="$base_dir"stitching/fusion/fusion_parallel.sh
export fusion_parallel_macro="$base_dir"stitching/fusion/fusion_parallel.ijm
export wait_for_jobs_to_finish_merge_bash_script="$base_dir"stitching/fusion/wait_for_jobs_to_finish_merge.sh
export wait_for_fusion_to_finish_oblique_to_coronal_bash_script="$base_dir"stitching/fusion/wait_for_fusion_to_finish_oblique_to_coronal.sh
export update_fused_image_resolution_macro="$base_dir"stitching/fusion/update_fused_image_resolution.ijm
export oblique_to_coronal_full_res_bash_script="$base_dir"stitching/fusion/oblique_to_coronal_full_res.sh
export oblique_to_coronal_iso_bash_script="$base_dir"stitching/fusion/oblique_to_coronal_iso.sh
export fusion_script="$base_dir"stitching/fusion/fusion.sh
export fusion_macro="$base_dir"stitching/fusion/fusion.ijm
export oblique_to_coronal_macro="$base_dir"stitching/oblique_to_coronal/oblique_to_coronal.ijm
export crop_fused_image_script="$base_dir"stitching/oblique_to_coronal/crop_fused_image.py
export define_bounding_box_macro="$base_dir"stitching/fusion/define_bounding_box.ijm

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
echo "Parallel: $parallel"
echo "Input Orientation: ${input_orientation}"
echo "Oblique -> Coronal: $oblique_to_coronal"
echo "Oblique -> Coronal (full res): $full_res_transformations"
echo "Output Resolution: $out_res"
echo "Output Resolution (isotropic): $out_res_isotropic"
echo ""
echo "Fusion Memory (upper bound): $fusion_memory"G
echo "Threads Per Job: $threads_per_job"
echo ""

# number of jobs
if [ $parallel = true ];
then
	export num_jobs=$((grid_size*grid_size))
	echo "# Parallel Jobs: $num_jobs"
	echo "Grid Size:" "$grid_size"x"$grid_size"
else
	export num_jobs=1
	echo "# Jobs: $num_jobs"
	
fi

# memory per thread for fusion
export memory_per_thread_fusion=$((fusion_memory/threads_per_job+1))
echo "Memory per Thread: $memory_per_thread_fusion"G


if [ $cluster = true ];
then

	if [ $parallel = true ];
	then
		
		echo ""
		echo "Running in parallel..."

		# create output directory 
		if [ $fuse_region = true ];
		then
			
			# create output directory
			export region_id="region_z${z_min}-${z_max}_y${y_min}-${y_max}"
			export output_data_path="${input_data_path}fusion_${out_res_z}um_parallel_${region_id}/"
			
		else
			export output_data_path="$input_data_path"fusion_"${out_res_z}"um_parallel/
		fi

		mkdir -p $output_data_path "$output_data_path"logs

		# copy fiji
		cp -r $fiji_path $output_data_path
		export imagej_exe=${output_data_path}Fiji.app/ImageJ-linux64
		chmod +x $imagej_exe
		echo "ImageJ Path: ${imagej_exe}"

		if [ $start_from_merge = true -o $start_from_oblique_to_coronal = true  ];
		then
			# this is for skip processing
			# can just start from merge if fusion parallel is complete
			# and you dont want to run again

			# dont need nohup here because qsub merge job should be submitted almost immediately

			$wait_for_jobs_to_finish_merge_bash_script

		else

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

			# job name
			export job_name="fusion_${out_res_z}um_parallel"
			echo "Job Name: $job_name"
			echo ""

			# run python script to create bounding boxes and save xml
			python $define_bounding_boxes_script $input_data_path $xml_file_name $grid_size $downsampling $output_data_path $fuse_region $z_min $z_max $y_min $y_max

			# modify dataset path in xml
			xml_name_no_ext=`echo "${xml_file_name%.*}"`
			sed -i 's/dataset/\.\.\/dataset/' "${output_data_path}${xml_name_no_ext}_bboxes_${grid_size}.xml"

			# update memory and threads for imagej
			$imagej_exe --headless --console -macro $update_imagej_memory_macro "$fusion_memory?$imagej_threads"

			# run job on cluster
			qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free="$((memory_per_thread_fusion*2))"G -t 1-$num_jobs $fusion_parallel_script`

			# parse qsub output to get job id
			export job_id=`echo $qsub_output | awk 'match($0,/[0-9]+/){print substr($0, RSTART, RLENGTH)}'`
			echo "Job ID: $job_id"
			echo ""

			# call merge volumes bash script to wait until all jobs are done
			# use nohup and run in background so if terminal is closed, script will persist
			echo "Wait for all fused volumes to complete and then merge..."
			echo ""

			nohup $wait_for_jobs_to_finish_merge_bash_script > "$output_data_path"logs/nohup_merge.out &
		fi

	else

		echo ""
		echo "Not Running in parallel...."
		echo ""

		# create output directory 
		export output_data_path="$input_data_path"fusion_"${out_res_z}"um/
		mkdir $output_data_path

		# copy fiji
		cp -r $fiji_path $output_data_path
		export imagej_exe=${output_data_path}Fiji.app/ImageJ-linux64
		chmod +x $imagej_exe
		echo "ImageJ Path: ${imagej_exe}"

		echo "Write Parameters..."
		echo "" >> "$output_data_path"params_fusion.txt
		echo "Input Data Path: $output_data_path" >> "$output_data_path"params_fusion.txt
		echo "XML Filename: $xml_file_name" >> "$output_data_path"params_fusion.txt
		echo "Downsampling: $downsampling" >> "$output_data_path"params_fusion.txt
		echo "Pixel Type: $pixel_type" >> "$output_data_path"params_fusion.txt
		echo "Interpolation: $interpolation" >> "$output_data_path"params_fusion.txt
		echo "blend: $blend" >> "$output_data_path"params_fusion.txt
		echo "" >> "$output_data_path"params_fusion.txt
		echo ""

		# job name
		export job_name="fusion_${out_res_z}um"

		# update memory and threads for imagej
		$imagej_exe --headless --console -macro $update_imagej_memory_macro "$fusion_memory?$imagej_threads"

		# run job on cluster
		qsub_output=`qsub -N $job_name -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free=$((memory_per_thread_fusion*2))G $fusion_script`

		if [ $oblique_to_coronal == true ];
		then

			# parse qsub output to get job id
			export job_id=`echo $qsub_output | awk 'match($0,/[0-9]+/){print substr($0, RSTART, RLENGTH)}'`
			echo "Job ID: $job_id"
			echo ""

			# wait for fusion to finish and then run oblique to coronal
			# use nohup and run in background so if terminal is closed, script will persist
			echo "Wait for fusion to complete and then oblique to coronal..."
			nohup $wait_for_fusion_to_finish_oblique_to_coronal_bash_script > "$output_data_path"nohup_oblique_to_coronal.out &

		fi

	fi


else


	#### NEED TO DEVELOP ####

	echo "Need to develop.."

	# update memory and threads for imagej
	#$imagej_exe --headless --console -macro $update_imagej_macrk_memory "$memory_total?$imagej_threads"

	# run fusion
	#$imagej_exe --headless --console -macro $fusion_macro "$input_data_path?$xml_file_name?$downsampling?$pixel_type?$interpolation?$blend"

	#fused_target_name=fused_oblique_"$out_res_x"x"$out_res_y"x"$out_res_z".tif
	#mv "$input_data_path"fused_tp_0_ch_0.tif $input_data_path$fused_target_name

fi

