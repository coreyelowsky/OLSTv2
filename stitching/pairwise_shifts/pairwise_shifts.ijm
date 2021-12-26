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

args = getArgument();
args = split(args, "?");

xml_path = args[0];
downsample_x = args[1];
downsample_y = args[2];
downsample_z = args[3];
num_z_volumes = parseInt(args[4]);
z_volume = parseInt(args[5]);
num_y_volumes = parseInt(args[6]);

print("Calculate Pairwise Shifts (ImageJ Macro)")
print("");
print("XML Path: " + xml_path);
print("Downsampling: " + downsample_x + " " + downsample_y + " " + downsample_z);
print("Total # Z Volumes in Dataset: " + num_z_volumes)
if(num_z_volumes > 1){
	print("Z Volume: " + z_volume);
}
print("Num Y: " + num_y_volumes);
print("");

print("Running - Calculate pairwise shifts");

xml_full_path = xml_path + "translate_to_grid.xml";

start_time = getTime();

if(num_z_volumes > 1){
	tiles = "";
	start = (z_volume-1)*num_y_volumes;
	end = start + 2*num_y_volumes - 1;
	for(i=start; i <=end; i++){

		if(i < end){
			tiles = tiles + i + ",";
		}else{
			tiles = tiles + i;
		}

	}
	print("Tiles:" + tiles);
}


if(num_z_volumes == 1){

	run("Calculate pairwise shifts ...", "select="+xml_full_path+" process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[All Timepoints] method=[Phase Correlation] downsample_in_x="+downsample_x+" downsample_in_y="+downsample_y+" downsample_in_z="+downsample_z);

}else{

	run("Calculate pairwise shifts ...", "select="+xml_full_path+" process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[Range of tiles (Specify by Name)] process_timepoint=[All Timepoints] process_following_tiles=" + tiles + " method=[Phase Correlation] downsample_in_x="+downsample_x+" downsample_in_y="+downsample_y+" downsample_in_z="+downsample_z);

}


print("Calculate pairwise shifts done");

end_time = getTime();

print("");
print('Time: ' + time_elapsed(start_time, end_time));
print("");

eval("script","System.exit(0);");
run("Quit");


