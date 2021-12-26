// ImageJ Macro to run Define Dataset in BigStitcher for the purpose of resaving data as N5 

// function to show time elapsed in readable format
function time_elapsed(start_time, end_time){

	time = (end_time - start_time) / 1000;

	if(time > 60){
		time /= 60;
		if (time > 60){
			time /= 60;
			if(time > 24){
				time /= 24;	
				return toString(time,1) + " days";
			}
			return toString(time,1) + " hours";
		}
		return toString(time,1) + " minutes";	
	}
	return toString(time,1) + " seconds";
}

// Parse Arguments
args = getArgument();
args = split(args, "?");

data_path = args[0];
voxel_size_x = args[1];
voxel_size_y = args[2];
voxel_size_z = args[3];
voxel_units = args[4];
compression = args[5];
subsampling_factors = args[6];
block_sizes = args[7];
num_threads = args[8];


print("");
print("Data Path: " + data_path);
print("Voxel Size: " + voxel_size_x + " " + voxel_size_y + " " + voxel_size_z);
print("Voxel Units: " + voxel_units);
print("Compression: " + compression);
print("Subsampling Factors: " + subsampling_factors);
print("Block Sizes: " + block_sizes);
print("# Threads: " + num_threads);


print("");
print("Save as N5...");

start_time = getTime();

run("Define dataset ...", "define_dataset=[Automatic Loader (Bioformats based)] project_filename=translate_to_grid.xml path="+data_path+" exclude=10 pattern_0=Tiles pattern_1=Tiles modify_voxel_size? voxel_size_x="+voxel_size_x+" voxel_size_y="+voxel_size_y+" voxel_size_z="+voxel_size_z+" voxel_size_unit="+voxel_units+" move_tiles_to_grid_(per_angle)?=[Move Tile to Grid (Macro-scriptable)] keep_metadata_rotation how_to_load_images=[Re-save as multiresolution N5] dataset_save_path="+data_path+" check_stack_sizes compression="+compression+" subsampling_factors="+subsampling_factors+" n5_block_sizes="+block_sizes+" number_of_threads="+num_threads);

end_time = getTime();

print("");
print('Time: ' + time_elapsed(start_time, end_time));
print("");

eval("script","System.exit(0);");
run("Quit");




