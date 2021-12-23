print("");
print("###################################");
print("Update Fused Image Resolution Macro");
print("###################################");
print("");


// Parse Arguments
args = getArgument();
args = split(args, "?");

input_data_path = args[0];
res_x = parseFloat(args[1]);
res_y = parseFloat(args[2]);
res_z = parseFloat(args[3]);

print("Res X: " + res_x);
print("Res Y: " + res_x);
print("Res Z: " + res_z);

// open image
image_path = input_data_path + "fused_oblique_"+res_x+"x"+res_y+"x"+res_z+".tif"
print("Opening Image: " + image_path);
open(image_path);


// set image resolution
run("Properties...", "unit=um pixel_width="+res_x+" pixel_height="+res_y+" voxel_depth="+res_z);

// save image
print("Saving Image: " + image_path);
saveAs("Tiff", image_path);


