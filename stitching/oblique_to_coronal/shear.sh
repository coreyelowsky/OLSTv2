#!/bin/bash

echo ""
echo "#####"
echo "Shear"
echo "#####"
echo ""

# move log files
sleep 5
mv "${cur_dir}"*${JOB_ID}* ${log_path}

# run shear
$imagej_exe --headless --console -macro $shear_macro "${input_image_path}?${output_image_path}?${shear_file}"


