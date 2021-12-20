#!/bin/bash

# This is the main script to run converting a fused image from oblique to coronal orientation
# This process is done to prepare brains for registration

####################################
######## For User to Modify ########
####################################

export inputDataPath=/grid/osten/data_nlsas_norepl/elowsky/OLSTv2/data/VIP-GFP-M2_stitching_output/oblique_grid_stitched_simple_global_optimization/
export filename=fused_oblique_3.70x3.70x25.tif

#####################################
#####################################
#####################################

# get base directory
export baseDir=$(dirname $0)/../

# set up script paths
export obliqueToCoronalMacro="$baseDir"oblique_to_coronal/oblique_to_coronal.ijm
export cropFusedImageScript="$baseDir"utilities/cropFusedImage.py

# import parameters
source "$baseDir"expert_params.sh

# figure out if running on cluster and export paths
isRunningOnCluster $HOSTNAME

echo ""
echo "##################"
echo "Oblique to Coronal"
echo "##################"
echo ""
echo "Input Data Path: $inputDataPath"
echo "File Name: $filename"
echo  ""


# update memory and threads for imagej
arguments="$memory_obliqueToCoronal?$imageJThreads"
$imageJEXE --headless --console -macro $updateImageJMemoryMacro "$arguments"

# run oblique to coronal macro
arguments="$inputDataPath?$filename?$shearFile"
$imageJEXE --headless --console -macro $obliqueToCoronalMacro "$arguments"

# crop sagittal 
python $cropFusedImageScript "$inputDataPath"?"sagittal"?25

# crop coronal
python $cropFusedImageScript "$inputDataPath"?"coronal"?25




