import sys
from shutil import rmtree
from os.path import join
from os import remove, system
sys.path.insert(1, join(sys.path[0], '..'))

from StitchingXML import StitchingXML

print()
print("#############################################")
print("Define Bounding Boxes XML for Parallel Fusion")
print("#############################################")
print()

# parse arguments
xml_path = sys.argv[1]
xml_file_name = sys.argv[2]
grid_size = int(sys.argv[3])
downsampling = float(sys.argv[4])
out_path = sys.argv[5]
fuse_region  = sys.argv[6]
z_min = int(sys.argv[7])
z_max = int(sys.argv[8])
y_min = int(sys.argv[9])
y_max = int(sys.argv[10])

if fuse_region == 'true':
	fuse_region = True
else:
	fuse_region = False

print('XML path:', xml_path)
print('XML file name:', xml_file_name)
print('Grid Size:', str(grid_size) + 'x' + str(grid_size))
print('Downsampling:', downsampling)
print('Outpath:', out_path)
print('Fuse Region:', fuse_region)

if fuse_region:
	print('Z:', str(z_min) + '-' + str(z_max))
	print('Y:', str(y_min) + '-' + str(y_max))

print()

# full xml path
xml_full_path = join(xml_path, xml_file_name)

print('XML full path:', xml_full_path)

# instantiate xml object
xml = StitchingXML(xml_full_path)

# define bounding boxes
xml.define_bounding_boxes_for_parallel_fusion(
		grid_size=grid_size, 
		downsampling=downsampling, 
		out_path=out_path,
		fuse_region=fuse_region,
		z_min=z_min,
		z_max=z_max,
		y_min=y_min,
		y_max=y_max)






