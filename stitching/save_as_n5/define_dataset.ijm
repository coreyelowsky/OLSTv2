// ImageJ Macro to run Define Dataset in BigStitcher
// The output of this script is an xml file 
// This script will not resave the data

// Parse Arguments
args = getArgument()
args = split(args, "?");

input_data_path = args[0];
output_data_path = args[1];
voxel_size_x = args[2];
voxel_size_y = args[3];
voxel_size_z = args[4];
tiles_x = args[5];
tiles_y = args[6];
overlap_x = args[7];
overlap_y = args[8];
grid_type = args[9];

print("");
print("Define datasets...");
print("");
print("Input Data Path: " + input_data_path);
print("Output Data Path: " + output_data_path);
print("Voxel Size: " + voxel_size_x + " " + voxel_size_y + " " + voxel_size_z);
print("Tile Size: " + tiles_x + " " + tiles_y);
print("Overlap: " + overlap_x + "% " + overlap_y + "%");
print("Grid Type: " + grid_type);
print("");

start_time = getTime();

run("Define dataset ...", "define_dataset=[Automatic Loader (Bioformats based)] project_filename=translate_to_grid.xml path="+input_data_path+" exclude=100 pattern_0=Tiles pattern_1=Tiles modify_voxel_size? voxel_size_x="+voxel_size_x+" voxel_size_y="+voxel_size_y+" voxel_size_z="+voxel_size_z+" voxel_size_unit=um move_tiles_to_grid_(per_angle)?=[Move Tile to Grid (Macro-scriptable)] grid_type="+grid_type+" tiles_x="+tiles_x+" tiles_y="+tiles_y+" tiles_z=1 overlap_x_(%)="+overlap_x+" overlap_y_(%)="+overlap_y+" overlap_z_(%)=10 keep_metadata_rotation how_to_load_images=[Load raw data virtually (with caching)] dataset_save_path="+output_data_path);

end_time = getTime();

print("");
print('Time: ' + (end_time-start_time)/1000/60 + " minutes");
print("");

eval("script","System.exit(0);");
run("Quit");

