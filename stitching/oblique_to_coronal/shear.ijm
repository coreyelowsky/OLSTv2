print("");
print("####################");
print("Shear (ImageJ Macro)");
print("####################");
print("");

// parse arguments
args = getArgument();
args = split(args, "?");

input_image_path = args[0];
output_image_path = args[1];
shear_file_path = args[2];

print("Parameters:");
print("Input Image: " + input_image_path);
print("Output Image: " + output_image_path);
print("Shear File: " + shear_file_path);
print("");

print("Shear...");
run("shear ","inputpath=" + input_image_path+ " shearfile=" + shear_file_path + " outputpath=" + output_image_path);

eval("script","System.exit(0);");
run("Quit");

