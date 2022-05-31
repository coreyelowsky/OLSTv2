#!/bin/bash

export tile_mip_screentools_script=/grid/osten/data_norepl/palmer/OLSTv2/stitching/tile_screening/tile_mip_screentools.py
export pos_tile_folder=/grid/osten/data_norepl/palmer/tile_screening_test/positive_tiles/
export neg_tile_folder=/grid/osten/data_norepl/palmer/tile_screening_test/negative_tiles/

#set to folder with either max intensity projection files or Z##_Y## files
#MODIFY ME
export test_tile_folder=/grid/osten/data_norepl/qi/data/morphology/AVP/AVP-IHC-A3/downsample2/volumes/

#MODIFY ME
export output_csv_file=/grid/osten/data_norepl/qi/data/morphology/AVP/AVP-IHC-A3/downsample2/tile_screening_results_AVP-IHC-A3.csv

#set to folder with Z##_Y## files or to $test_tile_folder if input is Z##_Y## files
export orig_tile_folder=$test_tile_folder

#positive folder with Z##_Y## files after processing
#MODIFY ME
export copy_to_folder=/grid/osten/data_norepl/qi/data/morphology/AVP/AVP-IHC-A3/downsample2/AVP-IHC-A3_positives/

#set to 1 if input is max intensity or set to size of single Z##_Y## file
export memory_usage=30

qsub -l job_mem_free=${memory_usage}G /grid/osten/data_norepl/palmer/OLSTv2/stitching/tile_screening/perform_tile_screening.sh
