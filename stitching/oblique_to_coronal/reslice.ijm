print("");
print("######################");
print("Reslice (ImageJ Macro)");
print("######################");
print("");

// parse arguments
args = getArgument();
args = split(args, "?");

input_image_path = args[0];
output_image_path = args[1];
flip = args[2];
direction = args[3];

print("Parameters:");
print("Input Image: " + input_image_path);
print("Output Image: " + output_image_path);
print("Flip: " + flip);
print("Direction: " + direction)
print("");

print("Opening Image: " + input_image_path);
open(input_image_path);

print("Reslice...");
if(flip == "true"){
	run("Reslice [/]...", "output=0 start=" + direction + " flip avoid");
}else{
	run("Reslice [/]...", "output=0 start=" + direction + " avoid");
}

print("Saving...");
saveAs("Tiff", output_image_path);
print("");

eval("script","System.exit(0);");
run("Quit");

