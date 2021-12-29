#!/bin/bash

# This is the main script to run for saving dataset in N5 format

####################################
######## For User to Modify ########
####################################

# input and output paths
# input path assumes volumes folder exists
export in_path=/grid/osten/data_norepl/elowsky/test/
export out_path=/grid/osten/data_norepl/elowsky/test/

# resolution
export res_x=.78
export res_y=.78
export res_z=2.5

# memory per job
export memory_per_job=30

# grid layout
export grid_type="[Left & Down]"

# compression
export compression="Gzip"

# which resolutions to save
export subsampling_factors="[{{1,1,1},{2,2,1},{4,4,2},{8,8,4},{16,16,8},{32,32,16}}]"
export block_sizes="[{{128,128,64},{128,128,64},{128,128,64},{128,128,64},{128,128,64},{128,128,64}}]"

# units
export voxel_units="um"

# number of threads per job
export threads_per_job=24

#####################################
#####################################
#####################################

# check if overlap range file provided
overlap_range_path="${in_path}overlap_range.txt"
if [ ! -f $overlap_range_path ];then
	echo "Error: overlap_range.txt does not exist"
	exit
fi

# read in overlap 
x_overlap_line=`sed -n '1p' $overlap_range_path`
x_overlap_center=`echo $x_overlap_line | head -n1 | awk '{print $1;}'`
x_overlap_delta=`echo $x_overlap_line | head -n1 | awk '{print $2;}'`
y_overlap_line=`sed -n '2p' $overlap_range_path`
y_overlap_center=`echo $y_overlap_line | head -n1 | awk '{print $1;}'`
y_overlap_delta=`echo $y_overlap_line | head -n1 | awk '{print $2;}'`

# calculate x and y overlap to set for intiial grid
# set range to center + 2*delta to make sure overlap is big enough
overlap_x=$(echo "${x_overlap_center}+${x_overlap_delta}" | bc -l )
overlap_y=$(echo "${y_overlap_center}+${y_overlap_delta}" | bc -l )

# check if input directory has volumes folder
export in_path_volumes="${in_path}volumes/"

if [ ! -d $in_path_volumes ] 
then
	echo "Error: The input path does not have a directory called 'volumes' in it. You have either specified the wrong directory or need to create this directory and place the volumes in it!"
	exit
fi

# get current directory
export cur_dir=`pwd`"/"

# get base directory
export base_dir=$(dirname $0)/../../

# set up script paths
export define_dataset_macro="${base_dir}stitching/save_as_n5/define_dataset.ijm"
export modify_image_loader_script="${base_dir}stitching/save_as_n5/modify_xml_image_loader.py"
export save_n5_script="${base_dir}stitching/save_as_n5/save_as_n5.sh"
export save_n5_macro="${base_dir}stitching/save_as_n5/save_as_n5.ijm"
export generate_report_script="${base_dir}stitching/save_as_n5/generate_report.py"

# import parameters and functions
source "${base_dir}stitching/stitching_params.sh"

# figure out if running on cluster and export paths
is_running_on_cluster $HOSTNAME


# create output directory for logs
export out_path_logs="${out_path}save_as_n5/"
mkdir -p $out_path_logs "${out_path_logs}logs/"

# copy fiji
cp -r $fiji_path $out_path_logs
export imagej_exe=${out_path_logs}Fiji.app/ImageJ-linux64
chmod +x $imagej_exe


echo ""
echo "###########"
echo "Save as N5"
echo "###########"
echo ""
echo "Input Data Path: ${in_path_volumes}"
echo "Output Data Path: ${out_path}"
echo ""

# get number of volumes
export num_volumes=$(find $in_path_volumes -maxdepth 1 -name '*.tif' | wc -l)
echo "# Volumes: $num_volumes"
echo ""

# get number of tiles in each dimension
i=0
for volume_path in $in_path_volumes*.tif
do
	arr_in=(${volume_path//// })
	z_tiles=${arr_in[-1]:1:2}

	# make sure base 10
	first_character=${z_tiles:0:1}
	if [ "$first_character" -eq "0" ];
	then
		z_tiles=${z_tiles:1:2}
	fi
	
	if [ $i -eq 0 ]
	then
		start_z=$z_tiles
	fi

	end_z=$z_tiles

	i=$((i+1))
done

export z_tiles=$((end_z - start_z + 1))
export y_tiles=$((num_volumes/z_tiles))


# detect start z
export start_z=`ls ${in_path_volumes}*.tif | head -1 | xargs -n 1 basename`
start_z=${start_z:1:2}
start_z=$(echo $start_z | sed 's/^0*//')
echo "Start Z: ${start_z}"

echo "# Z Tiles: $z_tiles"
echo "# Y Tiles: $y_tiles"
echo ""

echo "Write Parameters..."
echo "" >> "${out_path_logs}params.txt"
echo "Input Data Path: ${in_path}" >> "${out_path_logs}params.txt"
echo "Output Data Path: ${output_data_path}" >> "${out_path_logs}params.txt"
echo "Voxel Units: ${voxel_units}" >> "${out_path_logs}params.txt"
echo "Overlap X: ${overlap_x}%" >> "${out_path_logs}params.txt"
echo "Overlap Y: ${overlap_y}%" >> "${out_path_logs}params.txt"
echo "Grid Type: ${grid_type}" >> "${out_path_logs}params.txt"
echo "Compression: ${compression}" >> "${out_path_logs}params.txt"
echo "Subsampling Factors: ${subsampling_factors}" >> "${out_path_logs}params.txt"
echo "Block Sizes: ${block_sizes}" >> "${out_path_logs}params.txt"
echo "" >> "${out_path_logs}params.txt"
echo ""

if [ $cluster = true ];
then

	# memory per thread
	export memory_per_thread=$((memory_per_job/threads_per_job+1))

	# set number of jobs to number of volumes
	export num_jobs=$num_volumes

	echo "Memory per Job: ${memory_per_job}G"
	echo "# Volumes: ${num_volumes}"
	echo "# Jobs: ${num_jobs}"
	echo "# Threads per Job: ${threads_per_job}"
	echo "Memory per Thread: ${memory_per_thread}G"
	echo ""

	# create N5 for merged output
	merged_n5_path="${out_path}dataset.n5/"
	echo "Merged N5 Path: $merged_n5_path"
	echo ""
	mkdir -p $merged_n5_path

	# generate xml for merged dataset by running define datasets
	echo "Generate XML..."
	echo ""
	$imagej_exe --headless --console -macro $define_dataset_macro $in_path_volumes?$out_path?$res_x?$res_y?$res_z?$y_tiles?$z_tiles?$overlap_x?$overlap_y?"$grid_type"

	# modify xml imageloader
	merged_xml_path="${out_path}translate_to_grid.xml"
	echo "Modifying XML Image loader..."
	echo "Merged XML Path: $merged_xml_path"
	python $modify_image_loader_script $merged_xml_path

	# generate reports
	python $generate_report_script $out_path

	# move volumes to job folders
	echo "Move volumes to job folders..."
	echo ""
	for (( i=1; i<$((num_volumes+1)); i++ ))
	do  

		# make directory for job
		job_folder_path="${in_path}volumes_${i}"
		mkdir $job_folder_path


		# get volume name
		z=$(( (i-1) / y_tiles + start_z))
		y=$(( (i-1) % y_tiles + 1))
	
		# make sure z is 2 digits
		if [ ${#z} -lt 2 ];
		then
			z=0${z}
		fi

		# make sure y is 2 digits
		if [ ${#y} -lt 2 ];
		then
			y=0${y}
		fi

		volume_id=Z${z}_Y${y}

		mv ${in_path_volumes}${volume_id}.tif $job_folder_path
	
	done


	# update memory and threads for imagej
	$imagej_exe --headless --console -macro $update_imagej_memory_macro "$memory_per_job?$imagej_threads"

	# save as n5 in parallel
	qsub -cwd -binding linear_per_task:1 -pe threads $((threads_per_job/2)) -l m_mem_free=$((2*memory_per_thread))G -t 1-$num_jobs $save_n5_script



else

	# NEED TO DEVELOP #

	# NOT RUNNING ON CLUSTER #
	
	
	echo "Need to Develop"

	# update memory and threads for imagej
	#arguments="$memory_saveN5?$imageJThreads"
	#$imageJEXE --headless --console -macro $updateImageJMemoryMacro "$arguments"

	# save as n5
	#arguments="$inputDataPath?$outputDataPath?$resX?$resY?$resZ?$voxelUnits?$gridType?$yTiles?$zTiles?$overlapY?$overlapZ?$compression?$subsamplingFactors?$blockSizes?$threadsPerJob_saveN5"
	#$imageJEXE --headless --console -macro $saveN5Macro "$arguments"

	#rm "$outputDataPath"dataset.xml

fi




