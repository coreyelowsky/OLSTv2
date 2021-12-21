import numpy as np
from skimage.io import imread,imsave
from os.path import join
from sklearn.metrics import pairwise_distances

# This script can be used to find potential mistakes in a markup
# There are two ways mistakes can be found
# Set DISTANCE_CHECK or COUNT_CHECK to be True depending on which potential mistake you want to check
# 1) Distance Check
#	- if two voxels with the same label are very far away, then you may have marked up two distinct cells with same label
# 2) Count Check
#	- if there are not so many voxels of a certain label, the this may be a mistake


#########################################
DATA_PATH = '/data/elowsky/OLSTv2/markup/xiaoli_markups/PV-GFP-M2/cortex/'
IMAGE_NAME = "Z17_Y09-1"
RES_FACTORS = np.array([2.5,.37,.37])
DISTANCE_CHECK = True
COUNT_CHECK = True
#####################################

# load labels
labels = imread(join(DATA_PATH,IMAGE_NAME+'_labels.tif'))

# get unique labels, disgard 0 (background)
unique_labels = np.unique(labels)[1:]

print()
print('# Centroids:',len(unique_labels))
print()

global_distances = []
global_counts = []

# iterate through centroids
for i,unique_label in enumerate(unique_labels):

	if i % 10 == 0:
		print(i) 

	# get all voxels of centroids
	cell_voxels = np.argwhere(labels == unique_label)

	# check furthest distance between 2 voxels of same label
	distances = np.round(pairwise_distances(cell_voxels)).astype(int)
	max_distance = np.max(distances)
	max_distance_index = np.argwhere(distances == max_distance)[0]
	voxel_a, voxel_b = list(cell_voxels[max_distance_index[0]][::-1]), list(cell_voxels[max_distance_index[1]][::-1])
	global_distances.append([max_distance,unique_label,voxel_a,voxel_b])

	# check count of voxels for one label
	num_pixels = len(cell_voxels)
	global_counts.append([num_pixels, unique_label, list(cell_voxels[0][::-1])])



# sort global lists
global_distances.sort()
global_distances.reverse()
global_counts.sort()

if DISTANCE_CHECK:

	print('##############')
	print('Distance Check')
	print('##############')

	for distance_list in global_distances:

		print('Distance:',distance_list[0])
		print('Label:',distance_list[1])
		print('Voxel a:',distance_list[2])
		print('Voxel b:',distance_list[3])
	
		inp = input()
		if inp == 'n':
			break

print()
print()

if COUNT_CHECK:

	print('##############')
	print('Count Check')
	print('##############')

	for count_list in global_counts:

		print('Count:',count_list[0])
		print('Label:',count_list[1])
		print('Voxel:',count_list[2])

		inp = input()
		if inp == 'n':
			break

		






