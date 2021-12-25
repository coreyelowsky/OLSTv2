#!/bin/bash

echo ""
echo "###############################"
echo "Merge Fused Volumes Bash Script"
echo "###############################"
echo ""

# move log files
sleep 20
mv ${cur_dir}*${JOB_ID}* ${log_path}


# python script to merge volumes
python $merge_fused_volumes_python_script $merge_in_path $merge_out_path $downsampling $grid_size $merge_out_res


