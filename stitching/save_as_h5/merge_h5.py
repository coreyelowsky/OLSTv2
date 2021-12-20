import sys
import os
import h5py
import shutil
import time

from os.path import join, realpath

# add path to StitchingXML
dir_path = os.path.dirname(realpath(__file__))
sys.path.append(join(dir_path,'..'))

from StitchingXML import StitchingXML

# parse arguments
xml_path = sys.argv[1]
num_volumes = int(sys.argv[2])

# create xml object to use functions
xml = StitchingXML(join(xml_path, 'translate_to_grid.xml'), sectioning=False)

print('XML Path: ', xml_path)
print('# Volumes: ', num_volumes)

# create final h5
merged_h5_path = join(xml_path, 'dataset.h5')
with h5py.File(merged_h5_path, 'w') as h5_merged:
	
	print("Initialized merged h5..")

	# create group for timepoint
	merged_timepoint_group = h5_merged.create_group("t00000")

	# iterate through volumes folders to merge individual h5 sequentially
	for i in range(1, num_volumes + 1):
		
		volumes_path = join(xml_path, 'volumes_' + str(i))
		h5_path = join(volumes_path, 'dataset.h5')

		print('Volume: ', volumes_path)

		# read from individual h5
		# copy to merged

		start_time = time.time()

		with h5py.File(h5_path, 'r') as h5_volume:
		
			# if first volume then copy over data types
			if i == 1:
				source = h5_volume['__DATA_TYPES__']
				dest = h5_merged
				h5_merged.copy(source, dest)
			
			# copy over resolution info
			# calculate s value
			if num_volumes <= 100:
				s_source = 's' + '{:02d}'.format(0)
				s_dest = 's' + '{:02d}'.format(i-1)
			elif num_volumes <= 1000:
				s_source = 's' + '{:02d}'.format(0)
				s_dest = 's' + '{:03d}'.format(i-1)
			elif num_volumes <= 10000:
				s_source = 's' + '{:02d}'.format(0)
				s_dest = 's' + '{:03d}'.format(i-1)

			source = h5_volume[s_source]
			dest = h5_merged
			h5_merged.copy(source, dest, name=s_dest)

			# copy over data
			source = h5_volume['/t00000/' + s_source]
			dest = merged_timepoint_group
			h5_merged.copy(source, merged_timepoint_group, name=s_dest)
				
			# mv volume back
			volume_id = xml.setup_id_to_volume(i-1)
			source = join(volumes_path, volume_id+'.tif')
			dest = join(xml_path, 'volumes',volume_id+'.tif' )
			os.rename(source, dest)

			#delete folder
			shutil.rmtree(volumes_path)

		elapsed_time = time.time() - start_time
		if elapsed_time < 60:
			print(elapsed_time, 'seconds')
		elif elapsed_time < 60*60:
			print(elapsed_time/60, 'minutes')
		elif elapsed_time < 60*60*24:
			print(elapsed_time/60/60, 'hours')
		else:
			print(elapsed_time)
			



			


		
	








