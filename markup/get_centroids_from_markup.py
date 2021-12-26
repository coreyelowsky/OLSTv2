import numpy as np
import os
from skimage.io import imread

# This script takes the marked up ground truth labels and calculates
# the centroid coordinates and somes simplte cell statistics
# Centroids are saved to both .npy file and .csv file in the following format
# z, y, x, volume, average intensity, max intensity

######################################
RAW_PATH = '/data/elowsky/OLSTv2/markup/xiaoli_markups/PV-GFP-M2/thalamus/1/'
DATA_PATH = '/data/elowsky/OLSTv2/markup/xiaoli_markups/PV-GFP-M2/thalamus/1/'
IMAGE_NAME = 'Z22_Y17-1'
RES_FACTORS = np.array([2.5,.37,.37])
SAVE = True
########################################

# load in label image and raw image
#raw_image = imread(os.path.join(RAW_PATH,IMAGE_NAME+'.tif'))
labels = imread(os.path.join(DATA_PATH,IMAGE_NAME+'_labels.tif'))

# get unique labels (ignoring 0)
unique_labels = np.unique(labels)[1:]
num_cells = len(unique_labels)

print()
print('# Centroids:', num_cells)
print()

#centroids = np.zeros(shape=(0,7),dtype=np.uint32)
centroids = np.zeros(shape=(0,3),dtype=np.uint32)


# loop through unique labels
for unique_label in unique_labels:

	# get all voxels with unique label
	cell_voxels = np.argwhere(labels == unique_label)

	# calulate centroid by taking mean
	centroid = np.round(np.mean(cell_voxels,axis=0)).astype(int)[::-1]

	# calculate volume of centroid
	#volume = np.round(len(cell_voxels)*np.prod(RES_FACTORS)).astype(int)

	# get intensites
	#intensities = raw_image[cell_voxels[:,0],cell_voxels[:,1],cell_voxels[:,2]]

	# calculate average intensity
	#average_intensity = intensities.mean().round().astype(int)

	# calculate max intensity
	#max_intensity = intensities.max()

	#centroid_info = np.array([centroid[0], centroid[1], centroid[2], volume, average_intensity,max_intensity,len(intensities)])

	# append to output array
	#centroids = np.vstack((centroids,centroid_info))
	centroids = np.vstack((centroids, centroid))

if SAVE:
	#np.savetxt(os.path.join(DATA_PATH,IMAGE_NAME+'_CENTROIDS.csv'),centroids,delimiter=',',fmt=['%d','%d','%d','%d','%d','%d','%d'])
	np.savetxt(os.path.join(DATA_PATH,IMAGE_NAME+'_CENTROIDS.csv'),centroids,delimiter=',',fmt=['%d','%d','%d'])
	
	

