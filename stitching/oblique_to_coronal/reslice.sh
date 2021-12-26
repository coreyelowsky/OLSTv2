#!/bin/bash

echo ""
echo "#######"
echo "Reslice"
echo "#######"
echo ""

# move log files
sleep 5
mv "${cur_dir}"*${JOB_ID}* ${log_path}


# run reslice
$imagej_exe --headless --console -macro $reslice_macro "${input_image_path}?${output_image_path}?${flip}?${direction}"


