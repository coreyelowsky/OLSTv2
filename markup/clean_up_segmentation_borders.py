import numpy as np
from skimage.io import imread, imsave
from skimage.filters import threshold_otsu
from skimage import measure
import matplotlib.pyplot as plt
import os
import sys
import copy

# This script real first remove any markups that have intensity less than otsu
# Then the order of labels will be fixed so ids will be from 1 to num cells
# Then connected components analysis will be done to remove all non connected markups for each cell
# This is done because after remove labels less than otsu, there will be some stray non connected voxels
# It may not be a neccessary step, but removes noise and makes each cell fully connected

#########################################
DATA_PATH = '/data/elowsky/OLST_2/markup/ground_truth_gold_standard/'
RAW_PATH = '/data/elowsky/OLST_2/markup/raw_volumes/'
IMAGE_NAME = 'Z02_Y08_1707'
SAVE = True
OTSU_DECAY_RATE = .95
#####################################

print()
print('#####################################')
print('Clean Up Borders and Re-Order Labels')
print('#####################################')

# read in raw image and labels
raw_image = imread(os.path.join(RAW_PATH,IMAGE_NAME+'_raw.tif'))
labels = imread(os.path.join(DATA_PATH,IMAGE_NAME+'_labels.tif'))

# get number of centroids
num_centroids_before = len(np.unique(labels))-1

print()
print('# Cells (Before):', num_centroids_before)
print()

# get otsu threshold
otsu_thresh = threshold_otsu(raw_image)
print('Removing Bad Borders...')
print('Otsu Threshold:', otsu_thresh)

while True:

	# make labels copy
	labels_copy = copy.deepcopy(labels)

	# remove any markups less than otsu
	labels_copy[raw_image < otsu_thresh] = 0

	# fix labeling order
	# need to reorder because cells with all voxels below otsu threshold could be removed
	fixed_labels = np.zeros_like(labels_copy)
	unique_labels = np.unique(labels_copy)[1:]

	for i,unique_label in enumerate(unique_labels, start=1):
		cell_voxels = np.argwhere(labels_copy == unique_label)
		fixed_labels[cell_voxels[:,0], cell_voxels[:,1],cell_voxels[:,2]] = i



	unique_labels = np.unique(fixed_labels)[1:]
	num_centroids_after = len(unique_labels)

	print()
	print('# Cells (After):',num_centroids_after)
	print()

	# alert if # cells has changed
	if num_centroids_before != num_centroids_after:
		print('WARNING: # centroids has changed, Decrease Threshold!')
		print()

	# if number of centroids has changes, decrase otsu threshold
	if num_centroids_before == num_centroids_after:
		labels = fixed_labels
		break
	else:
		otsu_thresh = int(otsu_thresh*OTSU_DECAY_RATE)
		print('Threshold:',otsu_thresh)

print('Removing non-connected components...')
for unique_label in unique_labels:

	if unique_label % 25 == 0:
		print(unique_label)

	# get all connected components with labels
	cell_connected_image = (labels==unique_label).astype(np.uint8)
	connected_labels, num_labels = measure.label(cell_connected_image,return_num=True)

	# get all connected components of individual centroid
	# remove all minor non-connected components
	ids_to_remove = list(range(1,num_labels+1))
	max_i, max_num_voxels = -1, -1

	# iterate through connected components
	for i in range(1,num_labels+1):
		num_voxels = np.sum(connected_labels == i)
		if num_voxels > max_num_voxels:
			max_i = i
			max_num_voxels = num_voxels
	ids_to_remove.remove(max_i)

	# remove ids of smaller components
	for id_ in ids_to_remove:
		voxels = np.argwhere(connected_labels == id_)
		labels[voxels[:,0],voxels[:,1],voxels[:,2]] = 0

if SAVE:
	imsave(os.path.join(DATA_PATH,IMAGE_NAME+'_labels_removed_bad_borders.tif'),labels,check_contrast=False)




