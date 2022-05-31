// ImageJ Macro to prepocess image stacks (concat, rotate, flipz)

// Parse Arguments
args = getArgument()
args = split(args, "?");

z_folder = args[0];
output_data_path = args[1];
flip_z = args[2];
rotate = args[3];
dir_prefix = args[4];
downsample_bool = args[5];
downsample_xy = args[6];
z_id = parseInt(args[7]);
y_id = parseInt(args[8]);
stacks_per_volume = parseInt(args[9]);
max_project=args[10];
output_max_project_path=args[11];

print("");
print("#################################");
print("Concat Rotate FlipZ ImageJ Macro")
print("#################################");
print("");
print("PARAMETERS:");
print("Input Data Path: " + z_folder);
print("Output Data Path: " + output_data_path);
print("Flip Z: " + flip_z);
print("Rotate: " + rotate);
print("Max Project: " + max_project);
print("Max Project Output Path: " + output_max_project_path);
print("Directory Prefix: " + dir_prefix);
print("Downsample: " + downsample_bool);
print("Downsample_xy: " + downsample_xy);
print("Z: " + z_id);
print("Y: " + y_id);
print("Stacks per volume: " + stacks_per_volume);

start_time = getTime();

// allow expandale arrays
setOption("ExpandableArrays", true);

// helper function to print array
function print_array(array){
	for(i=0; i < array.length; i++){
		print(array[i]);
	}
}

// helper function to get volume ID from z and y
function get_volume_id(z,y){
	if(z <= 9){
		z_id = '0' + z;
	}else{
		z_id = z;
	}

	if(y <= 9){
		y_id = '0' + y;
	}else{
		y_id = y;
	}

	return 'Z' + z_id + '_Y' + y_id;
}

// function to show time elapsed in readable format
function time_elapsed(start_time, end_time){

	time = (end_time - start_time) / 1000;

	if(time > 60){
		time /= 60;
		if (time > 60){
			time /= 60;
			if(time > 24){
				time /= 24;	
				return toString(time,1) + " days";
			}
			return toString(time,1) + " hours";
		}
		return toString(time,1) + " minutes";	
	}
	return toString(time,1) + " seconds";
}


print("Begin Processing...");

print("");
print("Z Folder: " + z_folder);
print("");

// get y stacks and remove all files that are not .tif
y_stacks_all = getFileList(z_folder);
y_stacks = newArray;
y_index = 0;
for(i=0; i < y_stacks_all.length; i++){
	if(endsWith(y_stacks_all[i],".tif")  ){
		y_stacks[y_index] = y_stacks_all[i];
		y_index += 1;
	}
}

// get file name prefix
prefix = substring(y_stacks[0],0,indexOf(y_stacks[0],'Pos')) + 'Pos';


// get volume id
volume_id = get_volume_id(z_id,y_id);
print('Volume ID: ' + volume_id);

// open all stacks in volume
time_open_start = getTime();
for(stack_index=0; stack_index < stacks_per_volume; stack_index++){

	if(stack_index == 0){
		stack_name = prefix + (y_id-1) + ".ome.tif";
	}else{
		stack_name = prefix + (y_id-1) + "_" + stack_index +".ome.tif";
	}
	
	// open stack
	time_open = getTime();
	print("Loading: " + stack_name);
	open(z_folder + stack_name);
	time_open_end = getTime();
	print("Time to Load Image "+(stack_index+1) +": " + time_elapsed(time_open,time_open_end));

	// rename
	rename(stack_index);

	// downsample
	if(downsample_bool){
		downsample_scale_factor = 1.0 / downsample_xy;
		time_downsample_start = getTime();			
		run("Scale...", "x="+downsample_scale_factor+" y="+downsample_scale_factor+" z=1.0 interpolation=Bilinear average process create title=" + stack_index + "-downsampled");
		time_downsample_end = getTime();
		print('Time to Downsample: ' + time_elapsed(time_downsample_start,time_downsample_end));

		//select previous image and close
		//rename downsampled
		selectWindow(stack_index);
		close();
		call("java.lang.System.gc");
		run("Collect Garbage");
		selectWindow(stack_index + "-downsampled");
		rename(stack_index);
	}

}

// if need to concat
if(stacks_per_volume > 1){

	// generate concat string
	stack_string = "";
	for(stack_index=0; stack_index < stacks_per_volume; stack_index++){
		image_string = " image" + (stack_index+1) + "=" + stack_index;
		stack_string = stack_string + image_string;
	}
	

	time_start_concat = getTime();
	run("Concatenate...", "  title=" + stack_string);			
	time_end_concat = getTime();
	print('Time to Concatenate: ' + time_elapsed(time_start_concat,time_end_concat));
}

// flip Z
if(flip_z){
	time_flip_start = getTime();
	run("Flip Z");
	time_flip_end = getTime();
	print('Time to Flip Z: ' + time_elapsed(time_flip_start, time_flip_end));
}

// rotate
if(rotate){
	time_rotate_start = getTime();
	run("Rotate 90 Degrees Left");
	time_rotate_end = getTime();
	print('Time to Rotate: ' + time_elapsed(time_rotate_start,time_rotate_end));
}

// save stack
time_save_start = getTime();
saveAs("Tiff", output_data_path + volume_id + '.tif');
time_save_end = getTime();
print('Time to Write: ' + time_elapsed(time_save_start, time_save_end));

//max project
if(max_project){
	time_max_project_start = getTime();
	run("Z Project...", "projection=[Max Intensity]");
	time_max_project_end = getTime();
	print('Time to Max Project: ' + time_elapsed(time_max_project_start, time_max_project_end));
	saveAs("Tiff", output_max_project_path + 'MAX_' + volume_id + '.tif');
}

// close all windows
while(nImages > 0) {
	selectImage(nImages);
	close();
}
call("java.lang.System.gc");
run("Collect Garbage");

print('Time For Volume: ' + time_elapsed(time_open_start,time_save_end));

print("");

	
end_time = getTime();

print("");		
print("Total Time: " + time_elapsed(start_time,end_time));
print("");

eval("script","System.exit(0);");
run("Quit");





