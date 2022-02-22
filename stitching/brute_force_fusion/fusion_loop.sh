#!/bin/bash

export data_path=/grid/osten/data_norepl/elowsky/AVP_test/
export xml_path=${data_path}brute_force_xmls/

# get all xml files from path
xml_path_array=($(ls -d ${xml_path}*.xml))

# iterate through xml paths


for xml_full_path in "${xml_path_array[@]}"
do
	xml_name="${xml_full_path##*/}"
	xml_name="${xml_name%.*}"
	
	# call fusion main with xml path
	/grid/osten/data_norepl/elowsky/OLSTv2/stitching/brute_force_fusion/main.sh $xml_name
done





