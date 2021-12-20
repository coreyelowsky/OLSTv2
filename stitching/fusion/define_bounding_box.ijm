// Parse Arguments
args = getArgument();
args = split(args, "?");

data_path = args[0];
xml_file_name = args[1];
num_y = args[2];
min_z = args[3];
max_z = args[4];
min_y = args[5];
max_y = args[6];


// path to xml
xml_path = data_path + xml_file_name;

// generate string for tiles



//run("Define Bounding Box for Fusion", "select=/data/elowsky/drosophila/" + xml_path + " process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[Multiple tiles (Select from List)] process_timepoint=[All Timepoints] " + tile_string +  " bounding_box=[Maximal Bounding Box spanning all transformed views] bounding_box_name=["My Bounding"] minimal_x=-346 minimal_y=-717 minimal_z=-43 maximal_x=486 maximal_y=256 maximal_z=42");

