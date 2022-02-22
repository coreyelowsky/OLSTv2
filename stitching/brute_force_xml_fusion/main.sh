#!/bin/bash


################# PARAMETERS #################

data_path=/grid/osten/data_norepl/qi/data/PV/PV-GFP-M4/
xml_name=estimate_overlaps

# xml overlaps range
x_min=4
x_max=4
x_step=1
y_min=21
y_max=21
y_step=1
z_min=99
z_max=100
z_step=.5

##############################################


if [[ -d ${data_path}brute_force_xmls ]]; then
	echo ""
	echo "#####"
	echo "ERROR"
	echo "#####"
	echo ""
	echo "brute force xmls already exists.....please delete or rename..."
	echo ""
	exit
fi


# run python code to generate xmls
python /grid/osten/data_norepl/elowsky/OLSTv2/stitching/brute_force_xml_fusion/generate_brute_force_xmls.py $data_path $xml_name $x_min $x_max $x_step $y_min $y_max $y_step $z_min $z_max $z_step


brute_force_xml_path=${data_path}brute_force_xmls/

# get all xml files from path
xml_path_array=($(ls -d ${brute_force_xml_path}*.xml))

# iterate through xml paths
for xml_full_path in "${xml_path_array[@]}"
do
	xml_name="${xml_full_path##*/}"
	xml_name="${xml_name%.*}"
	
	# call fusion main with xml path
	/grid/osten/data_norepl/elowsky/OLSTv2/stitching/brute_force_xml_fusion/brute_force_fusion.sh $data_path $xml_name

done





