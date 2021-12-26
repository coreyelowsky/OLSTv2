from skimage.io import imread
from os.path import join
from os import remove
import sys
import numpy as np
import tifffile as tif
import math
import time
import gc

print('###################')
print('Merge Fused Volumes')
print('###################')
sys.stdout.flush()

# parse arguments
input_image_path = sys.argv[1]
output_image_path = sys.argv[2]
grid_size = sys.argv[3]
out_res = sys.argv[4]
delete = sys.argv[5]

print()
print('Input Image Path:', input_image_path)
print('Output Image Path:', output_image_path)
print('Grid Size:', grid_size)
print('Out Res:', out_res)
print('Delete:', delete)
print('')

# parse res
# if integer make ints
res = []
for x in out_res.split('x'):
	x = float(x)
	if math.floor(x) == x:
		x = int(x)
	res.append(x)
	
out_res_z = res[2]

# load all images
vertical_volumes = []

# concatenate vertically
for i in range(1, int(grid_size)**2 + 1):

	# get image path
	image_path = join(input_image_path, 'fused_' + str(i) + '.tif')
	
	# load image
	print('Loading:', image_path)
	sys.stdout.flush()
	image = imread(image_path)

	# either create new vertical volume or concat vertically
	if i % int(grid_size) == 1:
		vertical_volume = image
	else:
		vertical_volume = np.concatenate((vertical_volume,image),axis=1)

	# free memory
	del image
	gc.collect()

	# if finished vertically append to list
	if i % int(grid_size) == 0:
		vertical_volumes.append(vertical_volume)

# concatenate horizontally
print('Concatenate...')
sys.stdout.flush()
for i, vertical_volume in enumerate(vertical_volumes):

	if i == 0: 
		fused_volume = vertical_volume
	else:
		fused_volume = np.concatenate((fused_volume,vertical_volume),axis=2)
	
	# remove volume from memory
	del vertical_volume

# remove volumes
if delete == 'true':
	for i in range(1, int(grid_size)**2 + 1):
		remove(join(input_image_path,'fused_'+str(i)+'.tif'))


# save fused volume
print('Saving Fused Volume...')

out_res = 'x'.join([str(x) for x in res])
print('Out Res:', out_res)

out_path = join(output_image_path,'fused_oblique_' + out_res + '.tif')

print('Out Path:', out_path)
tif.imwrite(out_path, fused_volume, imagej=True, resolution=(1./res[0], 1./res[1]), metadata={'unit':'um', 'spacing':res[2], 'axes':'ZYX'})

print('Done writing image...')
