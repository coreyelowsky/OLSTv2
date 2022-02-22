from stitching.StitchingXML import StitchingXML
from os.path import join

########## Parameters ###########
xml_path = '/mnt/nfs/grids/hpc_norepl/qi/data/AVP/AVP-IHC-A3/downsample2/'
xml_name = 'estimate_overlaps.xml'
overlaps = {'x':6.1, 'y':22.5, 'z':99}
#################################

# create stitchign xml object
xml = StitchingXML(join(xml_path, xml_name))	

# sets overlaps in xml
xml.set_translation_to_grid_overlaps(overlaps)

# saves xml
xml_out_name = f'estimate_overlaps_{overlaps["x"]}_{overlaps["y"]}_{overlaps["z"]}'
xml.save_xml(xml_out_name)

# generate report (.txt) for new xml
xml = StitchingXML(join(xml_path, xml_out_name + '.xml'))	
xml.generate_report()

