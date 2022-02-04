from stitching.StitchingXML import StitchingXML
import params
import numpy as np
import tifffile as tif

from os import listdir, rename
from os.path import join




def volume_coord_to_coronal_cropped():

	xml_path = '/mnt/nfs/grids/hpc_norepl/qi/data/VIP/VIP-GFP-M4/estimate_overlaps.xml'
	xml = StitchingXML(xml_path)

	centroid = [237, 331, 1367]
	centroids = xml.transform_volume_coords_to_stitching_coords('Z11_Y09', centroid, ignore_stitching=True, shift_matrix=None)


	centroids = xml.stitching_coords_to_fused_image_coords(
			centroids,
			fused_image_type='coronal_cropped',
			downsampling=10, 
			isotropic=True, 
			cropping_coord=539)

	print(centroids)


def overlay():

	xml_path = '/mnt/nfs/grids/hpc_norepl/qi/data/PV/PV-GFP-M4/estimate_overlaps.xml'
	xml = StitchingXML(xml_path)
	
	xml.overlay_centroids_on_fused_image(
		fused_image_type = 'oblique',  
		centroids_path = '/mnt/brainstore8/palmer/OLSTv2/processed_brains/PV-GFP-M4/centroids/image_coords_no_overlap/', 
		z_res = 10, 
		isotropic=True, 
		outpath=None,
		cropping_coord=None, 
		image_shape=None, 
		write_centroids=False, 
		stop_volume=None)


def check_errors():
	
	print('check errors...')

	path = '/mnt/nfs/grids/hpc_norepl/qi/data/SST/SST-GFP-M2/save_as_n5/logs/'

	file_names = [x for x in listdir(path) if '.sh.o' in x]
	print(len(file_names))
	
	for file_name in sorted(file_names):
		
		with open(join(path, file_name), 'r') as fp:
			file_contents = fp.read()

			#if 'N5 resave finished' not in file_contents:
				#print(file_name)




	

	
		
if __name__ == '__main__':


	xml_path = '/mnt/nfs/grids/hpc_norepl/elowsky/AVP_test/pairwise_shifts.xml'
	xml = StitchingXML(xml_path)
	print(xml.pairwise_overlaps_1d)


	#overlaps = {'x':5.7, 'y':18, 'z':97.1}
	#xml.set_translation_to_grid_overlaps(overlaps)
	#xml.save_xml('estimate_overlaps')

	#xml_path = '/mnt/nfs/grids/hpc_norepl/qi/data/AVP/AVP-IHC-A2/downsample2/estimate_overlaps.xml'
	#xml = StitchingXML(xml_path)
	#xml.generate_report()
	

	"""
	volume = 'Z11_Y07'
	coords = [156, 530, 1971]
	fused_image_type = 'oblique'

	print()
	print('Volume:', volume)
	print('Volume Coords:', coords)
	print()

	stitching_coords = xml.transform_volume_coords_to_stitching_coords(volume, coords)
	print('Stitching Coords:', stitching_coords)

	transformed_coords = xml.volume_coords_to_fused_image_coords(
			volume=volume, 
			coords=coords, 
			fused_image_type=fused_image_type,
			z_res=5,
			isotropic=False,
			cropping_coord=0,
			region=False,
			z_min=9,
			z_max=11,
			y_min=8,
			y_max=10)

	print(fused_image_type + ':', transformed_coords)
	print()
	"""

	"""
	xml.overlay_centroids_on_fused_image( 
			fused_image_type='coronal_cropped', 
			centroids_path='/mnt/nfs/brainstore8/palmer/OLSTv2/processed_brains/GAD2-GFP-M4/centroids/image_coords_no_overlap/', 
			z_res=10, 
			isotropic=True, 
			outpath=None, 
			cropping_coord=None, 
			image_shape=None, 
			write_centroids=False, 
			stop_volume=None)
	"""






	





	




























