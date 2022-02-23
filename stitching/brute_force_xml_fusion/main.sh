#!/bin/bash

####################################
######## For User to Modify ########
####################################

# xml overlaps range
# xml will be create for all combinations
export x_min_overlap=4
export x_max_overlap=4
export x_step_overlap=1

export y_min_overlap=20
export y_max_overlap=30
export y_step_overlap=5

export z_min_overlap=97
export z_max_overlap=97
export z_step_overlap=.5

# input directory
export input_data_path=/grid/osten/data_norepl/qi/data/AVP/AVP-IHC-A2/downsample2/downsample2_whole/

# xml filename
# DO NOT INCLUlDE .xml EXTENSON
export xml_file_name=estimate_overlaps

# merged memory
export merge_memory_multiplier=4
export custom_merge_memory=false
export merge_memory=2500

# if true, will automtically set merge_full_res_fused_image=true
# and will compute the isotropic image from the full res image
# otherwise will downsample the grid of fusions
export compute_isotropic_from_full_res=false

# if true will save full res fused image
# this is ignored if compute_isotropic_from_full_res=true
export merge_full_res_fused_image=false

# if true then assumes the image has been already fused
# and will start from downsample
export start_from_downsample=false

# if true then assumes that grid of fused images have already
# been created and will start at merge step
export start_from_merge=false

# if true then assumes the image has been already fused
# and merged and will start from oblique to coronal
export start_from_oblique_to_coronal=false

# output resolution for z
export out_res_z=25

# grid dimensions for parallel fusion
# e.g. if grid_size=2, will be a 2x2 grid -> 4 jobs
export grid_size=5

# if only want to fuse a small section then set to true
# otherwise set to false
export fuse_region=true
export z_min=9
export z_max=13
export y_min=8
export y_max=12

# whether to run oblique -> coronal transformations
export oblique_to_coronal_isotropic=true
export oblique_to_coronal_full_res=false

# please make either 'coronal' or 'sagittal'
# this is needed for oblique to coronal orientation
export input_orientation=coronal

# memory for fusion jobs
# this does not need to be increased for larger datasets
# since big stitcher saves images on the fly
export fusion_memory=10

# threads per job
# minumum is 2 since 2 threads corresponds to one physical core (slot)
# each physical slot (core) has 2 logical cores (threads)
export threads_per_job=12

# priority for fusion job
# 0 is the highest priority allowed
# make negative integers if lower priority (e.g. priority=-1)
export priority=0

# whether to run in parallel or not
# if not running on the cluster this will be ignored
export parallel=true

# output pixel type
export pixel_type="[16-bit unsigned integer]"

# interpolation type
export interpolation="[Linear Interpolation]"

# blending
export blend=true

#####################################
#####################################
#####################################

#make sure .n5 exists
if [ ! -d ${input_data_path}dataset.n5 ]; then
  
	echo ""
	echo "#####"
	echo "Error"
	echo "#####"
	echo ""
	echo "dataset.n5 does not exist..."
	echo ""
fi


# if brute 
if [[ -d ${input_data_path}brute_force_xmls || -d ${input_data_path}brute_force_fusions ]]; then
	echo ""
	echo "#####"
	echo "ERROR"
	echo "#####"
	echo ""
	echo "brute force xmls or brute force fusions already exists.....please delete or rename directory..."
	echo ""
	exit
fi


# run python code to generate xmls
python /grid/osten/data_norepl/elowsky/OLSTv2/stitching/brute_force_xml_fusion/generate_brute_force_xmls.py $input_data_path $xml_file_name $x_min_overlap $x_max_overlap $x_step_overlap $y_min_overlap $y_max_overlap $y_step_overlap $z_min_overlap $z_max_overlap $z_step_overlap

# output path where xmls will be saved to
brute_force_xml_path=${data_path}brute_force_xmls/

# get all xml files from path
xml_path_array=($(ls -d ${brute_force_xml_path}*.xml))

# iterate through xml paths
for xml_full_path in "${xml_path_array[@]}"
do
	export xml_file_name="${xml_full_path##*/}"
	export xml_file_name="${xml_file_name%.*}"
	
	# call fusion main with xml path
	/grid/osten/data_norepl/elowsky/OLSTv2/stitching/brute_force_xml_fusion/brute_force_fusion.sh

done





