import sys
import os

# add path to StitchingXML
dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(dir_path,'..'))

from StitchingXML import StitchingXML

# parse arguments
xml_path = sys.argv[1]
sectioning = sys.argv[2]
num_z_volumes = int(sys.argv[3])

print("XML Path: ", xml_path)
print("Sectioning: ", sectioning)
print("# Z Volumes: ", num_z_volumes)

# full xml path
xml_full_path = os.path.join(xml_path, 'translate_to_grid.xml')

# convert sectioning to boolean
if sectioning == 'true':
	sectioning = True
elif sectioning == 'false':
	sectioning = False

# instantiate xml object
xml = StitchingXML(xml_full_path, sectioning=sectioning)

# merge pairwise shifts
xml.merge_pairwise_shifts()

# load xml and generate report
xml_pairwise_path = os.path.join(xml_path, 'pairwise_shifts.xml')
xml = StitchingXML(xml_pairwise_path, sectioning=sectioning)
xml.generate_report()






