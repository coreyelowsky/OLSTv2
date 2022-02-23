#!/bin/bash

echo ""
echo "##################"
echo "Crop (Bash Script)"
echo "##################"
echo ""

# move log files
sleep 5
mv "${cur_dir}"*${JOB_ID}* ${log_path}

python $crop_python_script "${input_image_path}?${output_image_path}?${crop_out_path}?${crop_res_x}?${crop_res_y}?${crop_res_z}?${max_proj}?${xml_file_name}"




