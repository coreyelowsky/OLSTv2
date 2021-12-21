import numpy as np
from skimage.io import imread,imsave
from os.path import join

# This script will re order labels so ids go from 1 to num cells
# Running this script is not necessary since this will be done in 'remove incorrect borders.py'

#########################################
DATA_PATH = "/data/elowsky/OLST_2/markup/"
IMAGE_NAME = "Z02_Y08_1707"
SAVE = True
#####################################

# load labels
labels_path = join(DATA_PATH,IMAGE_NAME+'_labels.tif')
labels = imread(labels_path)

# array to store fixed labels
fixed_labels = np.zeros_like(labels)

# get unique labels, disgard 0 (background)
unique_labels = np.unique(labels)[1:]

print()
print('# Cells:',len(unique_labels)-1)
print()

for i,unique_label in enumerate(unique_labels):
	
	if i % 10 == 0:
		print(i)

	# get all voxels of specific label
	cell_voxels = np.argwhere(labels == unique_label)

	# give voxels ordered label in output image
	fixed_labels[cell_voxels[:,0], cell_voxels[:,1],cell_voxels[:,2]] = i+1

if SAVE:
	out_path = join(DATA_PATH,IMAGE_NAME +'_labels_order_fixed.tif')
	imsave(out_path, fixed_labels, check_contrast=False)
