print("");
print("####################################");
print("Downsample To Isotropic ImageJ Macro");
print("####################################");
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
res_x = parseFloat(args[2]);
res_y = parseFloat(args[3]);
res_z = parseFloat(args[4]);

print("##########");
print("Parameters");
print("##########");

print("Input Image Path: " + input_image_path);
print("Output Image Path: " + output_image_path);
print("Res X: " + res_x);
print("Res Y: " + res_y);
print("Res Z: " + res_z);

print("");

// open image

print("Opening Image: " + input_image_path);
open(input_image_path);


// downsample to isotropic resolution
downsample_scale_factor = res_x / res_z;

print("Downsample to Isotropic...");
print("Downsample Factor: " + downsample_scale_factor);
run("Scale...", "x="+downsample_scale_factor+" y="+downsample_scale_factor+" z=1.0 interpolation=Bilinear average process create");

print("Saving...");
saveAs("Tiff", output_image_path);
print("");

eval("script","System.exit(0);");
run("Quit");
