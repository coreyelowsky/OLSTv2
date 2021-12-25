from skimage.io import imread
import tifffile as tif
import numpy as np
import matplotlib.pyplot as plt
import sys
from os.path import join

print()
print('################')
print('Crop Fused Image')
print('################')
print()
sys.stdout.flush()

# parse arguments
args = sys.argv[1]
args = args.split('?')

input_image_path = args[0]
output_image_path = args[1]
output_path = args[2]
res_x = args[3]
res_y = args[4]
res_z = args[5]
res = [res_x, res_y, res_z]

# get orientation
if 'coronal' in input_image_path:
	orientation = 'coronal'
elif 'sagittal' in input_image_path:
	orientation = 'sagittal'
elif 'transverse' in input_image_path:
	orientation = 'transverse'
else:
	sys.exit('Error: unable to parse orientation')

print('Input Image Path:', input_image_path)
print('Output Image Path:', output_image_path)
print('Output Path:', output_path)
print('Orientation:', orientation)
print('Resolution:', res_x + 'x' + res_y + 'x' + res_z)
print('')
sys.stdout.flush()

# load image
print('Loading Image...')
sys.stdout.flush()
image = tif.imread(input_image_path)
print('Image Shape:', image.shape)
print()
sys.stdout.flush()

if orientation == 'transverse':
	# find plane index of front and back non zeros voxels
	print('Find Highest and Lowest Non-Zero Voxels...')
	for z in range(image.shape[0]):
		if np.any(image[z, :, :]):
			front_non_zero_index = z
			break

	for z in range(image.shape[0]-1, -1, -1):
		if np.any(image[z, :, :]):
			back_non_zero_index = z
			break

	#non_zero_indices = np.argwhere(image)
	#front_non_zero_index = np.min(non_zero_indices[:,0])
	#back_non_zero_index = np.max(non_zero_indices[:,0])

	print('Front Non-Zero Index:', front_non_zero_index)
	print('Back Non-Zero Index:', back_non_zero_index)
	print()

	# write cropping info
	with open(join(output_path,'cropping_info_' + orientation + '.txt'),'w') as fp:
		fp.write(str(front_non_zero_index))
		fp.write('\n')
		fp.write(str(back_non_zero_index))
	
	# crop image
	print('Crop Image...')
	cropped_image = image[front_non_zero_index:back_non_zero_index+1,:,:]
	print('Cropped Image Shape', cropped_image.shape)
	print()

else:

	# find row index of highest and lowest non zeros voxels
	print('Find Highest and Lowest Non-Zero Voxels...')
	for y in range(image.shape[1]):
		if np.any(image[:, y, :]):
			highest_non_zero_index = y
			break

	for y in range(image.shape[1]-1, -1, -1):
		if np.any(image[:, y, :]):
			lowest_non_zero_index = y
			break
			
	#non_zero_indices = np.argwhere(image)
	#highest_non_zero_index = np.min(non_zero_indices[:,1])
	#lowest_non_zero_index = np.max(non_zero_indices[:,1])

	print('Highest Non-Zero Index:', highest_non_zero_index)
	print('Lowest Non-Zero Index:', lowest_non_zero_index)
	print()

	# write cropping info
	with open(join(output_path,'cropping_info_' + orientation + '.txt'),'w') as fp:
		fp.write(str(highest_non_zero_index))
	
	# crop image
	print('Crop Image...')
	cropped_image = image[:,highest_non_zero_index:lowest_non_zero_index+1,:]
	print('Cropped Image Shape', cropped_image.shape)
	print()

# set any voxels below background intensity to background intensity
print('Find Background Intensity...')
non_zero_intensities = cropped_image[cropped_image > 0]
n, bins, _ = plt.hist(non_zero_intensities, bins=1000)
peak_idx = np.argmax(n)
mean_background_intensity = int(np.round(bins[peak_idx]))
print()

print('Set Zero Voxels to Background Intensity...')
print('Background Intensity:', mean_background_intensity)
cropped_image[cropped_image < mean_background_intensity] = mean_background_intensity
print()

print('Save Image...')
sys.stdout.flush()
res = [float(x) for x in res]
tif.imwrite(output_image_path, cropped_image, imagej=True, resolution=(1./res[0], 1./res[1]), metadata={'unit':'um','spacing':res[2], 'axes':'ZYX'})
print()
print('Done!')

