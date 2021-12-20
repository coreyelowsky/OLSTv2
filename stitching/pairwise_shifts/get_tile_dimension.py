import sys
import os

# add path to StitchingXML
dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(dir_path,'..'))

from StitchingXML import StitchingXML

# read in arguments
xml_path = sys.argv[1]
dimension = sys.argv[2]

# instantiate stitching xml object
# sectioning doesnt matter here
xml = StitchingXML(xml_path, sectioning=False)

if  dimension == 'y':
	print(xml.num_y_volumes)
	sys.exit(0)
elif dimension == 'z':
	print(xml.num_z_volumes)
	sys.exit(0)
