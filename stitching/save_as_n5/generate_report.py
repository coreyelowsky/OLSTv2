import sys
import os

# add path to StitchingXML
dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(dir_path,'..'))

from StitchingXML import StitchingXML

# read in arguments
xml_path = sys.argv[1]

# instantiate stitching xml object
# sectioning doesnt matter here
xml_full_path = os.path.join(xml_path, 'translate_to_grid.xml')
xml = StitchingXML(xml_full_path, sectioning=False)

# modify image loader
xml.generate_report()
