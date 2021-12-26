print("");
print("#####################");
print("Rotate (ImageJ Macro)");
print("#####################");
print("");

// parse arguments
args = getArgument();
args = split(args, "?");

input_image_path = args[0];
output_image_path = args[1];

print("Parameters:");
print("Input Image: " + input_image_path);
print("Output Image: " + output_image_path);
print("");

print("Opening Image: " + input_image_path);
open(input_image_path);

print("Rotate...");
run("Rotate 90 Degrees Right");

print("Saving...");
saveAs("Tiff", output_image_path);
print("");

eval("script","System.exit(0);");
run("Quit");

