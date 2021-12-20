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
xml = StitchingXML(xml_path, sectioning=False)

# modify image loader
xml.modify_image_loader_for_saving_as_h5() 
