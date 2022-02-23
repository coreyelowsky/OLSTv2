import sys
import os
from os import listdir, rename, mkdir
from os.path import join, exists
import numpy as np

# add path to StitchingXML
dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(dir_path,'..'))

from StitchingXML import StitchingXML

# agruments
data_path = sys.argv[1]
xml_name = sys.argv[2]
x_min = float(sys.argv[3])
x_max = float(sys.argv[4])
x_step = float(sys.argv[5])
y_min = float(sys.argv[6])
y_max = float(sys.argv[7])
y_step = float(sys.argv[8])
z_min = float(sys.argv[9])
z_max = float(sys.argv[10])
z_step = float(sys.argv[11])

# make output directory
out_dir = join(data_path, 'brute_force_xmls')
if not exists(out_dir):
	mkdir(out_dir)

# make output directory
out_dir_fusion = join(data_path, 'brute_force_fusions')
if not exists(out_dir_fusion):
	mkdir(out_dir_fusion)


# get range lists
x_list = np.arange(x_min, x_max+x_step, x_step)
y_list = np.arange(y_min, y_max+y_step, y_step)
z_list = np.arange(z_min, z_max+z_step, z_step)

# load xml
xml = StitchingXML(join(data_path, xml_name + '.xml'))

for x_overlap in x_list:
	for y_overlap in y_list:
		for z_overlap in z_list:
			overlaps = {'x':x_overlap, 'y':y_overlap, 'z':z_overlap}
			xml.set_translation_to_grid_overlaps(overlaps)
			xml.modify_n5_path('../../dataset.n5')
			xml.save_xml(join(out_dir,f'estimate_overlaps_{x_overlap}_{y_overlap}_{z_overlap}'))

			xml_path = join(out_dir,f'estimate_overlaps_{x_overlap}_{y_overlap}_{z_overlap}.xml')
			xml = StitchingXML(xml_path)
			xml.generate_report()






	

	





	





	




























