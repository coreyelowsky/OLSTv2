#!/bin/bash

module load EBModules
module load Python/3.9.5-GCCcore-10.3.0

python $tile_mip_screentools_script $pos_tile_folder $neg_tile_folder $test_tile_folder $output_csv_file $orig_tile_folder $copy_to_folder
