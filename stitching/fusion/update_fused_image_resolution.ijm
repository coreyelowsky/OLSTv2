// Parse Arguments
args = getArgument();
args = split(args, "?");

input_data_path = args[0];
res_x = args[1];
res_y = args[2];
res_z = args[3];


// open image
image_path = input_data_path + "fused_oblique_"+res_x+"x"+res_y+"x"+res_z+".tif"
open(image_path);


// set image resolution
run("Properties...", "unit=um pixel_width="+res_x+" pixel_height="+res_y+" voxel_depth="+res_z);

// save image
saveAs("Tiff", image_path);

