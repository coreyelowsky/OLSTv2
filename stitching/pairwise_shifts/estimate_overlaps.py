import sys
import os

# add path to StitchingXML
dir_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(dir_path,'..'))

from StitchingXML import StitchingXML

print()
print('Estimate Overlaps - Python Script')
print()

# parse arguments
xml_path = sys.argv[1]
sectioning = sys.argv[2]
x_overlap_center = float(sys.argv[3])
x_overlap_delta = float(sys.argv[4])
y_overlap_center = float(sys.argv[5])
y_overlap_delta = float(sys.argv[6])

print("XML Path: ", xml_path)
print("Sectioning: ", sectioning)
print("X Overlap Center: ", x_overlap_center)
print("X Overlap Delta: ", x_overlap_delta)
print("Y Overlap Center ", y_overlap_center)
print("Y Overlap Center: ", y_overlap_delta)
print()


# rename pairwise shift

# full xml path
xml_full_path = os.path.join(xml_path, 'pairwise_shifts.xml')

# convert sectioning to boolean
if sectioning == 'true':
	sectioning = True
elif sectioning == 'false':
	sectioning = False

# instantiate xml object
xml = StitchingXML(xml_full_path, sectioning=sectioning)

# prepare constraints dict
overlap_dict = {
	'x':{},
	'y':{},
}
overlap_dict['x']['center'] = x_overlap_center
overlap_dict['x']['delta'] = x_overlap_delta
overlap_dict['y']['center'] = y_overlap_center
overlap_dict['y']['delta'] = y_overlap_delta

# estimate overlaps
xml.estimate_overlaps(set_overlaps_and_save=True, overlap_constraints=overlap_dict)

# generate report for estimate
xml_full_path = os.path.join(xml_path, 'estimate_overlaps.xml')
xml = StitchingXML(xml_full_path, sectioning=sectioning)
xml.generate_report()

# re-generate report for pairwise just in case
xml_full_path = os.path.join(xml_path, 'pairwise_shifts.xml')
xml = StitchingXML(xml_full_path, sectioning=sectioning)
xml.generate_report()











