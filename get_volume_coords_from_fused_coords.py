from stitching.StitchingXML import StitchingXML
from os.path import join, exists
from sys import exit

##################################################
FUSION_PATH = '/mnt/nfs/grids/hpc_norepl/qi/data/PV/PV-GFP-M4/fusion_25um_parallel/'
COORDS = [371, 244, 425]
#################################################


print()
print('#########################################')
print('Fused Coronal Cropped Coords -> Volume ID')
print('#########################################')
print()

print('Fusion Path:', FUSION_PATH)
print('Coords:', COORDS)
print()

# error if fusion path is not up to date
if 'um' not in FUSION_PATH:
	exit('Error: FUSION_PATH is old - ' + FUSION_PATH)

# make sure fusion path exists
if not exists(FUSION_PATH):
	exit('Error: FUSION_PATH does not exist - ' + FUSION_PATH)


# look for estimate overlaps
# should be one directory up
dataset_dir = '/'.join(FUSION_PATH.split('/')[:-2])

xml_path = join(dataset_dir, 'estimate_overlaps.xml')
if not exists(xml_path):
	exit('Error: estimate_overlaps.xml does not exists - ' + xml_path)

# load xml 
xml = StitchingXML(xml_path, sectioning=False)

# get volume id
volume_id = xml.fused_coronal_cropped_coords_to_volume_id(
		coords = COORDS, 
		fusion_path = FUSION_PATH)

print('Volume:', volume_id)
print()
	



