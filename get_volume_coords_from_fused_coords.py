from stitching.StitchingXML import StitchingXML
from os.path import join, exists
from sys import exit

##################################################
FUSION_PATH = '/mnt/nfs/grids/hpc_norepl/qi/data/AVP/AVP-IHC-A2/downsample2/'
COORDS = [1477, 1087, 1075]
#COORDS = [1503, 1087, 1075]
IMAGE_TYPE = 'sagittal_cropped'
RESOLUTION = 5
#################################################


print()
print('#########################################')
print('Fused Coronal Cropped Coords -> Volume ID')
print('#########################################')
print()

print('Fusion Path:', FUSION_PATH)
print('Coords:', COORDS)
print('Image Type:', IMAGE_TYPE)
print('Resolution:', RESOLUTION)
print()



# make sure fusion path exists
fusion_path = join(FUSION_PATH, f'fusion_{RESOLUTION}um')
if not exists(fusion_path):
	exit('Error: FUSION_PATH does not exist - ' + fusion_path)


# look for estimate overlaps
# should be one directory up
dataset_dir = '/'.join(fusion_path.split('/')[:-1])


xml_path = join(dataset_dir, 'estimate_overlaps.xml')
if not exists(xml_path):
	exit('Error: estimate_overlaps.xml does not exists - ' + xml_path)

# load xml 
xml = StitchingXML(xml_path, sectioning=False)

# get volume id
volume_id = xml.fused_coords_to_volume_id(
		coords = COORDS, 
		fusion_path = fusion_path,
		image_type=IMAGE_TYPE,
		res=RESOLUTION)

print('Volume:', volume_id)
print()
	



