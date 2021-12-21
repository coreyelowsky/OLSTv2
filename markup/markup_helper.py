import numpy as np
from skimage.io import imread, imsave
from skimage.filters import threshold_otsu
from skimage import measure
from os.path import join
import sys

# This script will allow show user potential areas of signal that has not been marked up yet
# First, the raw image is otsu thresholded to remove all background
# Then the already marked up labels are subtracted from the otsu thresholded image
# Connected componented are then printed out to user in descending order by intensity

#########################################
DATA_PATH = "/data/elowsky/OLSTv2/markup/xiaoli_markups/PV-GFP-M2/cortex/"
IMAGE_NAME = "Z17_Y09-1"
#####################################

# read in raw image and labels
raw_image = imread(join(DATA_PATH,IMAGE_NAME+'.tif'))
labels = imread(join(DATA_PATH,IMAGE_NAME+'_labels.tif'))

# threeshold labels
thresholded_labels = (labels>0).astype(np.uint8)

# make all pixels less than otsu 0
otsu_threshold = threshold_otsu(raw_image)
raw_image[raw_image < otsu_threshold] = 0

# subtract labels from raw image
subtracted = raw_image - raw_image*thresholded_labels
imsave(join(DATA_PATH,'sub.tif'), subtracted, check_contrast=False)

# get connected components
connected_labels, num_labels = measure.label((subtracted>0).astype(np.uint8),return_num=True)

print()
print('Calculating Potential Centroids...')
print('# Connected Components:',num_labels)
print()

# get all connected components of subtracted image and sort by count
sorted_components = []
for label in range(1,num_labels+1):

	# get voxels of labels
	voxels = np.argwhere(connected_labels == label)
	potential_centroid = np.round(np.mean(voxels,axis=0)).astype(int)

	# average intensity of all voxels
	intensity = raw_image[voxels[:,0],voxels[:,1],voxels[:,2]].mean().round().astype(int)
	sorted_components.append([potential_centroid,intensity,len(voxels)])

# sort by decreasing intensity
sorted_components = sorted(sorted_components, key = lambda x: x[1])[::-1]

# print out for user
for component in sorted_components:
	print('Coordinates:',component[0][::-1])
	print('Intensity:',component[1])
	print('# Voxels:',component[2])
	input()


coord = np.unravel_index(np.argmax(subtracted),subtracted.shape)


