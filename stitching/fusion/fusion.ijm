// ImageJ Macro to run fusion (parallel)

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

xml_full_path = args[0];
output_data_path = args[1];
xml_file_name = args[2];
downsampling = args[3];
pixel_type = args[4];
interpolation = args[5];
blend = args[6];
bbox_id = args[7];
grid_size = args[8];
parallel = args[9];

print("##########");
print("Parameters");
print("##########");

print("XML Path: " + xml_full_path);
print("Output Data Path: " + output_data_path);
print("XML Filename: " + xml_file_name );
print("Downsampling: " + downsampling);
print("Pixel Type: " + pixel_type);
print("Interpolation: " + interpolation);
print("Blend: " + blend);
print("Bbox id: " + bbox_id);
print("Grid Size: " + grid_size); 
print("Parallel: " + parallel);
print("");

print("Fuse Dataset...");

// create blend string
blend_string = " ";
if (blend){
	blend_string = " blend ";
}

start_time = getTime();

if(parallel == "true"){


	bounding_box = "[Bounding Box " + bbox_id + "]";

	// run fusion
	run("Fuse dataset ...", "select="+xml_full_path+" process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[All Timepoints] bounding_box="+bounding_box+" downsampling="+downsampling+" pixel_type="+pixel_type+" interpolation="+interpolation+" image=Virtual interest_points_for_non_rigid=[-= Disable Non-Rigid =-]"+blend_string+"preserve_original produce=[Each timepoint & channel] fused_image=[Save as (compressed) TIFF stacks] output_file_directory="+output_data_path+" filename_addition=["+bbox_id+"]");

	// full path to image that big stitcher saves after fusion
	output_image_path_full = output_data_path + bbox_id + "_fused_tp_0_ch_0.tif";

	// rename 
	File.rename(output_image_path_full, output_data_path + "fused_" + bbox_id + ".tif")
}else{

	// run fusion
	run("Fuse dataset ...", "select=" + xml_full_path + " process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[All Timepoints] bounding_box=[All Views] downsampling="+downsampling+" pixel_type="+pixel_type+" interpolation="+interpolation+" image=Virtual interest_points_for_non_rigid=[-= Disable Non-Rigid =-]"+blend_string+"preserve_original produce=[Each timepoint & channel] fused_image=[Save as (compressed) TIFF stacks] output_file_directory="+output_data_path);

}

end_time = getTime();

print("Time to fuse: " + time_elapsed(start_time,end_time));

eval("script","System.exit(0);");
run("Quit");
