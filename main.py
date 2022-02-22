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


def brute_force_xmls(
	x_min,
	x_max,
	x_step,
	y_min, 
	y_max, 
	y_step, 
	z_min, 
	z_max, 
	z_step,
	xml_path,
	out_path):

	x_list = np.arange(x_min, x_max+1, y_step)
	y_list = np.arange(y_min, y_max+1, y_step)
	z_list = np.arange(z_min, z_max+1, z_step)

	xml = StitchingXML(xml_path)

	for x_overlap in x_list:
		for y_overlap in y_list:
			for z_overlap in z_list:

		
				overlaps = {'x':x_overlap, 'y':y_overlap, 'z':z_overlap}
				xml.set_translation_to_grid_overlaps(overlaps)
				xml.save_xml(join(out_path,f'estimate_overlaps_{y_overlap}_{z_overlap}'))

				xml_path = join(out_path,f'estimate_overlaps_{y_overlap}_{z_overlap}.xml')
				xml = StitchingXML(xml_path)
				xml.generate_report()






	

	
		
if __name__ == '__main__':


	#xml_path = '/mnt/nfs/grids/hpc_norepl/elowsky/AVP_test/pairwise_shifts.xml'
	#xml = StitchingXML(xml_path)
	#print(xml.pairwise_overlaps_1d)


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

	"""
	x_min = 6.4
	x_max = 6.4
	x_step = 1
	y_min = 12
	y_max = 28
	y_step = 2
	z_min = 97
	z_max = 97
	z_step = 1

	xml_path = '/mnt/nfs/grids/hpc_norepl/elowsky/AVP_test/translate_to_grid.xml'
	out_path = '/mnt/nfs/grids/hpc_norepl/elowsky/AVP_test/brute_force_xmls/'

	#brute_force_xmls(x_min, x_max, x_step, y_min, y_max, y_step, z_min, z_max, z_step, xml_path, out_path)
	"""

	# save one xml with specified overlap
	
	#xml_path = '/mnt/nfs/grids/hpc_norepl/qi/data/AVP/AVP-IHC-A2/downsample2/downsample2_whole/estimate_overlaps.xml'
	#xml = StitchingXML(xml_path)	


	#overlaps = {'x':6.4, 'y':22, 'z':97}
	#xml.set_translation_to_grid_overlaps(overlaps)
	#xml.save_xml('estimate_overlaps_6.4_22_97')


	xml_path = '/mnt/nfs/grids/hpc_norepl/qi/data/AVP/AVP-IHC-A2/downsample2/downsample2_whole/estimate_overlaps_6.4_22_97.xml'
	xml = StitchingXML(xml_path)	
	xml.generate_report()

	





	




























