print("");
print("########################");
print("Downsample ImageJ Macro");
print("########################");
print("");

// function to round to any number of decimal places
function my_round(value, n){

	value = value * pow(10,n);
	value = round(value);
	value = value / pow(10,n);

	return value
}

// Parse Arguments
args = getArgument();
args = split(args, "?");

input_image_path = args[0];
output_image_path = args[1];

print("##########");
print("Parameters");
print("##########");

print("Input Image Path: " + input_image_path);
print("Output Image Path: " + output_image_path);

print("");

// open image

print("Opening Image: " + input_image_path);
open(input_image_path);
getPixelSize(unit, res_x, res_y, res_z);
res_x = my_round(res_x, 2);
res_y = my_round(res_y, 2);
res_z = my_round(res_z, 2);
print("Resolution: " + res_x + " " + res_y + " " + res_z); 
print("");

// downsample to isotropic resolution
downsample_scale_factor = res_x / res_z;

print("Downsample to Isotropic...");
print("Downsample Factor: " + downsample_scale_factor);
run("Scale...", "x="+downsample_scale_factor+" y="+downsample_scale_factor+" z=1.0 interpolation=Bilinear average process create");

print("Saving...");
saveAs("Tiff", output_image_path);
print("");

// delete original
File.delete(input_image_path);

eval("script","System.exit(0);");
run("Quit");
