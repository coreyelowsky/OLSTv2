///////////////////////////////////////////
DATA_PATH = "/data/elowsky/OLSTv2/markup/xiaoli_markups/";
IMAGE_NAME = "raw";
KEY_PRESS_WAIT_TIME_SECONDS = 0.5;
///////////////////////////////////////////

// open raw data
open(DATA_PATH + IMAGE_NAME + ".tif");

// if labels image exists, load image
// otherwise create image
if(!File.exists(DATA_PATH + IMAGE_NAME + "_labels.tif")){
	run("Duplicate...", "title="+IMAGE_NAME+"_labels.tif"+" duplicate");
	selectWindow(IMAGE_NAME + "_labels.tif");
	run("Multiply...", "value=0 stack");
	saveAs("Tiff", DATA_PATH +IMAGE_NAME+"_labels.tif");
}else{
	open(DATA_PATH + IMAGE_NAME + "_labels.tif");
}


// get max value in image
selectWindow(IMAGE_NAME + "_labels.tif");
Stack.getStatistics(voxelCount, mean, min, max, stdDev);
wait(KEY_PRESS_WAIT_TIME_SECONDS*1000);
label_value = max + 1;
print("Label Value: " + label_value);

// set initial contrast
run("Brightness/Contrast...");
setMinAndMax(0, 1);

while(true){

	if(isKeyDown("space")){
		selectWindow(IMAGE_NAME + "_labels.tif");
		run("Multiply...", "value=0 slice");
		run("Add...", "value="+label_value+" slice");
		wait(KEY_PRESS_WAIT_TIME_SECONDS*1000);
		run("Select None");		
		selectWindow(IMAGE_NAME + ".tif");
		run("Select None");
		selectWindow(IMAGE_NAME + "_labels.tif");		
		run("Next Slice [>]");
	}

	if(isKeyDown("shift")){
		label_value += 1;
		print("Label Value: " + label_value);
		wait(KEY_PRESS_WAIT_TIME_SECONDS*1000);

	}

}



