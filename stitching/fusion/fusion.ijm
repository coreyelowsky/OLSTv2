// ImageJ Macro to run fusion

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

// Parse Arguments
args = getArgument();
args = split(args, "?");

input_data_path = args[0];
output_data_path = args[1];
xml_file_name = args[2];
downsampling = args[3];
pixel_type = args[4];
interpolation = args[5];
blend = args[6];

print("##########");
print("Parameters");
print("##########");

print("Input Data Path: " + input_data_path);
print("Output Data Path: " + output_data_path);
print("XML Filename: " + xml_file_name );
print("Downsampling: " + downsampling);
print("Pixel Type: " + pixel_type);
print("Interpolation: " + interpolation);
print("Blend: " + blend);
print("");

print("Fuse Dataset...");

start_time = getTime();

xml_full_path = input_data_path + xml_file_name;

blend_string = " ";
if (blend){
	blend_string = " blend ";
}

run("Fuse dataset ...", "select="+xml_full_path+" process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[All Timepoints] bounding_box=[Currently Selected Views] downsampling="+downsampling+" pixel_type="+pixel_type+" interpolation="+interpolation+" image=Virtual interest_points_for_non_rigid=[-= Disable Non-Rigid =-]"+blend_string+"preserve_original produce=[Each timepoint & channel] fused_image=[Save as (compressed) TIFF stacks] output_file_directory="+output_data_path+" filename_addition=[]");

end_time = getTime();

print("Time to fuse: " + time_elapsed(start_time,end_time));

eval("script","System.exit(0);");
run("Quit");
