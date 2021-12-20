from StitchingXML import StitchingXML
from os.path import join

#### params ####
xml_path = '/mnt/nfs/grids/hpc_norepl/elowsky/PV-GFP-M2/'
sectioning = True
#################

print()
print("##################################")
print("Estimate Overlaps (Python Script)")
print("##################################")
print()

# full xml name
xml_full_path = join(xml_path,'pairwise_shifts.xml')
 
# instantiate xml object and estimate overlaps
xml = StitchingXML(xml_full_path, sectioning=sectioning)
xml.estimate_overlaps(set_overlaps_and_save=True)

# instantiate xml object for estimate overlaps and generate report
xml_full_path = join(xml_path,'estimate_overlaps.xml')
xml = StitchingXML(xml_full_path, sectioning=sectioning)
xml.generate_report()






