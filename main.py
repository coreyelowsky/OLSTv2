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

	xiaoli = 'corey'
	#check_errors()

	#overlay()
	"""
	xml_path = '/mnt/nfs/grids/hpc_norepl/qi/data/PV/PV-GFP-M4/estimate_overlaps.xml'
	xml = StitchingXML(xml_path)

	volume = 'Z13_Y09'
	p1 = [167, 328, 2242]
	z_res = 10
	isotropic=True

	
	#fused_dims = xml.calculate_fused_dimensions(preserve_anisotropy=True, z_res=10)
	#print(fused_dims)
	#fused_lengths = np.array([fused_dims['x']['length'],fused_dims['y']['length'],fused_dims['z']['length']])

	#print('Fused Image Size', fused_lengths)


	stitching_coords = xml.transform_volume_coords_to_stitching_coords(volume, p1)

	print('Stitching Coord:', stitching_coords)

	centroid = xml.stitching_coords_to_fused_image_coords(
			stitching_coords,
			fused_image_type='oblique',
			z_res=z_res, 
			isotropic=isotropic, 
			cropping_coord=0,
			preserve_anisotropy=True)

	print('Final:',centroid)
	"""





	





	




























