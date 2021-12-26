// function to round to any number of decimal places
function my_round(value, n){

	value = value * pow(10,n);
	value = round(value);
	value = value / pow(10,n);

	return value;
}


print("");
print("#################################");
print("Oblique -> Coronal (ImageJ Macro)");
print("#################################");
print("");

// parse arguments
args = getArgument();
args = split(args, "?");

input_data_path = args[0];
file_name = args[1]
shear_file_path = args[2];
input_orientation = args[3];
res_x = parseFloat(args[4]);
res_y = parseFloat(args[5]);
res_z = parseFloat(args[6]);

print("Parameters:");
print("Input Image: " + input_data_path);
print("File Name: " + file_name);
print("Shear File: " + shear_file_path);
print("Input Orientation: " + input_orientation);
print("Res X: " + res_x);
print("Res Y: " + res_y);
print("Res Z: " + res_z);
print("");

// full path to image
input_image_path_full = input_data_path + file_name;
print("Input Image Path: " + input_image_path_full);


// open image
print("Opening Image: " + input_image_path_full);
open(input_image_path_full);
res_x = my_round(res_x, 2);
res_y = my_round(res_y, 2);
res_z = my_round(res_z, 2);
print("Resolution: " + res_x + " " + res_y + " " + res_z); 
print("");

// reslice dimensions and vertical flip
print("Reslice and Vertical Flip...");
run("Reslice [/]...", "output=0 start=Left flip avoid");

print("Saving...");
reslice_path = output_data_path + "fused_oblique_resliced_"+ res_y + "x" + res_z + "x" + res_x+".tif";
saveAs("Tiff", reslice_path);
print("");

// close previous windows
selectWindow("fused_oblique_" + res_x + "x" + res_y + "x" + res_z + ".tif");
close();
call("java.lang.System.gc");
selectWindow("fused_oblique_resliced_"+ res_y + "x" + res_z + "x" + res_x + ".tif");

// shear
print("Shear...");
if(input_orientation == "coronal"){
	sheared_path = output_data_path + "fused_sagittal_" + res_y + "x" + res_z + "x" + res_x+ ".tif";
}else if(input_orientation == "sagittal"){
	sheared_path = output_data_path + "fused_sheared_" + res_y + "x" + res_z + "x" + res_x+ ".tif";
}
run("shear ","inputpath="+reslice_path+" shearfile="+shear_file_path+" outputpath="+sheared_path);
print("");

// close all windows to clear memory
close("*");
call("java.lang.System.gc");

// Open Sagittal
print("Opening Sagittal...");
open(sheared_path);
print("");

// reslice dimensions
print("Reslice...");
run("Reslice [/]...", "output=0 start=Left avoid");
print("Saving...");
if(input_orientation == "coronal"){
	saveAs("Tiff", output_data_path + "fused_sagittal_resliced_" + res_x + "x" + res_z + "x" + res_y+ ".tif");
}else if(input_orientation == "sagittal"){
	saveAs("Tiff", output_data_path + "fused_sagittal_" + res_x + "x" + res_z + "x" + res_y+ ".tif");
}
print("");

if(input_orientation == "coronal"){
	// close sagittal
	selectWindow("fused_sagittal_" + res_y + "x" + res_z + "x" + res_x + ".tif");
	close();
	call("java.lang.System.gc");
	selectWindow("fused_sagittal_resliced_" + res_x + "x" + res_z + "x" + res_y + ".tif");

	// rotate for coronal
	print("Rotate...");
	run("Rotate 90 Degrees Right");
	print("Saving...");
	saveAs("Tiff", output_data_path + "fused_coronal_" + res_x + "x" + res_z + "x" + res_y+ ".tif");
	print("");

	// reslice dimensions for transverse
	print("Reslice...");
	run("Reslice [/]...", "output=0 start=top avoid");
	print("Saving...");
	saveAs("Tiff", output_data_path + "fused_transverse_"+ res_x + "x" + res_y + "x" + res_z+".tif");
	print("");
}

// end script
eval("script","System.exit(0);");
run("Quit");

