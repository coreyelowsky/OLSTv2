print("");
print("##############################");
print("Modify Image Resolution Macro");
print("##############################");
print("");


// Parse Arguments
args = getArgument();
args = split(args, "?");

input_data_path = args[0];
output_data_path = args[1];
res_x = parseFloat(args[2]);
res_y = parseFloat(args[3]);
res_z = parseFloat(args[4]);

print("Res X: " + res_x);
print("Res Y: " + res_x);
print("Res Z: " + res_z);

// open image
print("Opening Image: " + input_data_path);
open(input_data_path);


// set image resolution
run("Properties...", "unit=um pixel_width="+res_x+" pixel_height="+res_y+" voxel_depth="+res_z);

// save image
print("Saving Image: " + output_data_path);
saveAs("Tiff", output_data_path);

