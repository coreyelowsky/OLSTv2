"""
provides functions to parse/analyze Stitching XML file from Big Stitcher

	- when referring to coordinates of volumes
		- x: left-right
		- y: top-bottom
		- z: front-back

	- when referring to volumes themselves
		- y: right-left
		- z: top-bottom
 
"""

import xml.etree.ElementTree as ET
import numpy as np
import copy
import math

from sys import exit
from os.path import dirname, join

class StitchingXML():

	def __init__(self, xml_path, *, sectioning, sectioning_interval=3):

		# path of xml
		self.xml_path = xml_path

		# sectioning means that brain is not cut every z-slice and instead more than 1 z-slices are imaged and then cut
		self.sectioning = sectioning
		self.sectioning_interval = sectioning_interval

		# objects to access xml
		self.tree = ET.parse(xml_path)
		self.root =  self.tree.getroot()

		# parse xml and store information
		self.setups, self.volume_size, self.voxel_size, self.anisotropy_factor = self.parse_setups()
		self.transforms = self.parse_transforms()
		self.pairwise_shifts = self.parse_pairwise_shifts()
		
		# calculate how many volumes in each dimension
		self.num_volumes, self.num_z_volumes, self.num_y_volumes = self.infer_volume_dimensions()

		# store all correlations in 1d list
		self.correlations_1d = {}
		self.correlations_1d['x'] = self.correlations_to_1d_list('x')
		self.correlations_1d['y'] = self.correlations_to_1d_list('y')
		self.correlations_1d['xy'] = self.correlations_to_1d_list('xy')
		self.correlations_1d['non adjacent'] = self.correlations_to_1d_list('non adjacent')

		# arrange correlations into 2d grid
		self.correlations_2d = {}
		self.correlations_2d['x'] = self.correlations_to_2d_list('x')
		self.correlations_2d['y'] = self.correlations_to_2d_list('y')
		self.correlations_2d['xy'] = self.correlations_to_2d_list('xy')

		# arrange transform overlaps into 1d list 2d grid
		self.transform_overlaps_1d, self.transform_overlaps_2d = {}, {}
		self.transform_overlaps_1d['x'], self.transform_overlaps_2d['x'] = self.arrange_overlaps_grid('x', 'transform')
		self.transform_overlaps_1d['y'], self.transform_overlaps_2d['y'] = self.arrange_overlaps_grid('y', 'transform')
		self.transform_overlaps_1d['z'], self.transform_overlaps_2d['z'] = self.arrange_overlaps_grid('z', 'transform')

		# arrange pairwise overlaps into 1d list 2d grid
		self.pairwise_overlaps_1d, self.pairwise_overlaps_2d = {}, {}
		self.pairwise_overlaps_1d['x'], self.pairwise_overlaps_2d['x'] = self.arrange_overlaps_grid('x', 'pairwise')
		self.pairwise_overlaps_1d['y'], self.pairwise_overlaps_2d['y'] = self.arrange_overlaps_grid('y', 'pairwise')
		self.pairwise_overlaps_1d['z'], self.pairwise_overlaps_2d['z'] = self.arrange_overlaps_grid('z', 'pairwise')

		
	@staticmethod
	def reslice(coords, image_lengths):

		return coords[[1,2,0]], image_lengths[[1,2,0]]

	@staticmethod
	def vertical_flip(coords, image_lengths):
	
		coords[1] = image_lengths[1] - coords[1] - 1

		return coords

	@staticmethod
	def shear(coords, image_lengths, shear_factor):
		
		image_lengths_shear = copy.deepcopy(image_lengths)
		image_lengths_shear[1] = image_lengths[1] + abs(shear_factor)*image_lengths_shear[0]
		image_lengths_shear = np.round(image_lengths_shear).astype(int)

		coords[1] = coords[1] - image_lengths[1]/2 + shear_factor*(coords[0]-image_lengths[0]/2) + image_lengths_shear[1]/2 + 1		

		return coords, image_lengths_shear

	@staticmethod
	def rotate(coords,imageLengths):

		coords = coords[[1,0,2]]
		coords[0] = imageLengths[1] - coords[0] - 1
	
		return coords, imageLengths[[1,0,2]]



	@staticmethod
	def bbox_rounding(value):

		"""
		rounds to number to higher magnitude	

		"""

		return math.ceil(value) if value > 0. else math.floor(value)

	@staticmethod
	def zy_to_volume(z, y):

		"""
		converts individual z and y to volume id

		"""

		return 'Z' + '{:02}'.format(z) + '_Y' + '{:02}'.format(y)

	@staticmethod
	def format_data_value_for_grid(data_value):

		"""
		formats data for display in grid

		"""

		if data_value is None:
			data_string = '  . '
		elif data_value == 0:
			data_string = '.00 '				
		elif data_value < 0:
			data_string = ' -  '
		elif data_value == 1:
			data_string = ' 1  '
		elif data_value >= 100:
			data_string = str(int(np.round(data_value))) + ' '
		else:
			data_string = str(data_value)

			if data_string.startswith('0.'):
				data_string = data_string[1:]

			if len(data_string) == 1 or len(data_string) == 2:
				data_string += '0 '
			elif len(data_string) == 3:
				data_string += ' '

		return data_string

	@staticmethod
	def matrix_to_string(matrix):

		"""
		converts 2d numpy array to string for xml

		"""

		return ' '.join(matrix.flatten().astype(str))


	def any_pairwise_shift_exists(self):

		"""
		return boolean whether any pairwise shifts exist in xml
	
		"""

		return self.pairwise_shifts != {}


	def setup_id_to_y(self, setup_id):

		"""
		converts setup id to y

		"""

		return (setup_id % self.num_y_volumes) + 1

	def setup_id_to_z(self, setup_id):

		"""
		converts setup is to z

		"""

		return (setup_id // self.num_y_volumes) + 1

	def setup_id_to_volume(self, setup_id):

		"""
		converts setup id to volume id (e.g. Z12_Y08)

		"""

		z = '{:02}'.format(self.setup_id_to_z(setup_id))
		y = '{:02}'.format(self.setup_id_to_y(setup_id))

		return 'Z' + z + '_Y' + y

	def volume_to_setup_id(self, volume):

		"""
		converts volume id (e.g. Z12_Y08) to setup id

		"""

		z = int(volume.split('_')[0][1:])
		y = int(volume.split('_')[1][1:])

		return (z-1)*self.num_y_volumes + (y-1)

	def zy_to_setup_id(self, z, y):

		"""
		converts z and y to setup id

		"""

		return (z-1)*self.num_y_volumes + (y-1)
		

	def volume_is_border(self, setup_id):

		"""
		returns dict of booleans whether volume is border

		"""

		# allow setup id to be volume id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		left = (((setup_id + 1) % self.num_y_volumes) == 0)
		right = (setup_id % self.num_y_volumes == 0)
		above = (setup_id < self.num_y_volumes)
		below = (setup_id >= (self.num_volumes - self.num_y_volumes))
		
		return {'left':left , 'right':right, 'above':above, 'below':below}

	def setup_id_is_valid(self, setup_id):

		"""
		boolean whether setup id is valid

		"""

		# allow setup id to be volume id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		return 0 <= setup_id < self.num_volumes


	def adjacent_volumes_setup_id(self, setup_id):

		"""
		calculates setup id of adjacent volumes
	
		"""

		# allow setup id to be volume id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		setup_ids_adjacent = {'left': None, 'right':None, 'above':None, 'below':None,'below left':None,'below right':None,'above left':None,'above right':None}
		if self.setup_id_is_valid(setup_id):
			if not self.volume_is_border(setup_id)['left']: 
				setup_ids_adjacent['left'] = setup_id + 1

			if not self.volume_is_border(setup_id)['right']: 
				setup_ids_adjacent['right'] = setup_id - 1

			if not self.volume_is_border(setup_id)['below']:
				setup_ids_adjacent['below'] = setup_id + self.num_y_volumes

			if not self.volume_is_border(setup_id)['above']:
				setup_ids_adjacent['above'] = setup_id - self.num_y_volumes

			if not self.volume_is_border(setup_id)['below'] and not self.volume_is_border(setup_id)['left']:
				setup_ids_adjacent['below left'] = setup_id + self.num_y_volumes + 1

			if not self.volume_is_border(setup_id)['below'] and not self.volume_is_border(setup_id)['right']:
				setup_ids_adjacent['below right'] = setup_id + self.num_y_volumes - 1

			if not self.volume_is_border(setup_id)['above'] and not self.volume_is_border(setup_id)['left']:
				setup_ids_adjacent['above left'] = setup_id - self.num_y_volumes + 1

			if not self.volume_is_border(setup_id)['above'] and not self.volume_is_border(setup_id)['right']:
				setup_ids_adjacent['above right'] = setup_id - self.num_y_volumes - 1


		return setup_ids_adjacent
			

	def parse_setups(self):

		"""
		parses setups and stores in dict where keys are setup id

		"""

		setups = {}

		# iterate through setups
		for setup in self.root.iter('ViewSetup'):
			
			setup_id = int(setup.find('id').text)
			volume_size = [int(x) for x in setup.find('size').text.split(' ')]
			voxel_size = [float(x) for x in setup.find('voxelSize').find('size').text.split(' ')]
			
			setups[setup_id] = {'volume size':volume_size, 'voxel size':voxel_size}

		
		# make sure all volumes sizes are the same
		volume_sizes = [v['volume size'] for k,v in setups.items()]
		if all(x == volume_sizes[0] for x in volume_sizes):
			volume_size = volume_sizes[0]
		else:
			exit('All Volume Sizes are not the same!!!')

		# make sure all voxel sizes are the same
		voxel_sizes = [v['voxel size'] for k,v in setups.items()]
		if all(x == voxel_sizes[0] for x in voxel_sizes):
			voxel_size = voxel_sizes[0]
		else:
			exit('All Voxel Sizes are not the same!!!')
		
		# calculate anisotropy factor
		anisotropy_factor = voxel_size[2]/voxel_size[1]

		return setups, volume_size, voxel_size, anisotropy_factor


	def parse_transforms(self):

		"""	
		parses transformations and stores in dict where keys are setup id

		"""
		
		transforms = {}

		# iterate through view registrations
		for registration in self.root.iter('ViewRegistration'):

			# get setup id
			setup_id = int(registration.attrib['setup'])

			# create new dict within transforms dict for setup
			transforms[setup_id] = {}

			# iterate through transformation matrices
			for transform in registration.iter('ViewTransform'):

				# get name of transformation matrix
				name = transform.find('Name').text

				# change name to more concise name
				if name == 'Translation to Regular Grid':
					name = 'translation'
				elif name == 'Stitching Transform':
					name = 'stitching'
				elif name == 'calibration':
					name = 'calibration'
				else:
					exit('Error: transform name is not valid...')
				
				# reshape the matrix and store in dict
				matrix = np.array([float(x) for x in transform.find('affine').text.split()]).reshape(3,4)
				transforms[setup_id][name] = matrix

		return transforms


	def parse_pairwise_shifts(self):
		
		"""
		parses pairwise stitchings and stores dict where keys are set of setup ids

		"""

		pairwise_shifts = {}

		# iterate through pairwise shifts
		for pairwise in self.root.iter('PairwiseResult'):

			# get both setup ids
			setup_a = int(pairwise.attrib['view_setup_a'])
			setup_b = int(pairwise.attrib['view_setup_b'])

			shift = np.array([float(x) for x in pairwise.find('shift').text.split()]).reshape(3,4)
			correlation = np.round(float(pairwise.find('correlation').text),2)
			bbox = [float(x) for x in pairwise.find('overlap_boundingbox').text.split()]

			pairwise_shifts[frozenset({setup_a,setup_b})] = {'setup a':setup_a,'setup b':setup_b, 'shift':shift,'correlation':correlation,'bounding box':bbox}
		

		return pairwise_shifts


	def infer_volume_dimensions(self):
		
		"""
		calculates number of Y and Z volumes based on translation to grid matrices

		"""

		# get x for first volume (top right)
		x1 = self.get_transform(0, 'translation')['x']

		for setup_id in sorted(self.transforms.keys()):
			
			if setup_id > 0:			
				x2 = self.get_transform(setup_id, 'translation')['x']

				# handle case if only one Z
				if setup_id == len(self.transforms)-1:
					num_y_volumes = setup_id + 1

				# reached next Z
				if x1 == x2:
					num_y_volumes = setup_id
					break

		num_z_volumes = int(len(self.setups)/num_y_volumes)

		num_volumes = num_z_volumes*num_y_volumes

		if num_volumes != len(self.setups):
			exit('Error: Number of y and z volumes might not be infered correctly!')	

		return num_volumes, num_z_volumes, num_y_volumes

	
	def get_all_transforms(self, setup_id, *, square=False):

		"""
		- get all transform matrices for volume
		- option to return as square matrices

		"""
	
		# allow setup id to be volume id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		transforms = self.transforms[setup_id]
		out_transforms = {}		

		for transform in transforms:
			out_transforms[transform] = self.get_transform(setup_id, transform, square=square)['matrix']
			
		return out_transforms


	def get_pairwise_shift_dict(self, setup_id_a, setup_id_b):

		"""
		gets pairwise shift dict, order of setups is ignored
	
		"""

		# allow setup_id to be volume_id
		if str(setup_id_a).startswith('Z'):
			setup_id_a = self.volume_to_setup_id(setup_id_a)
		if str(setup_id_b).startswith('Z'):
			setup_id_b = self.volume_to_setup_id(setup_id_b)

		if frozenset({setup_id_a, setup_id_b}) in self.pairwise_shifts:
			return self.pairwise_shifts[frozenset({setup_id_a, setup_id_b})]
		else:
			return None

	def get_pairwise_shift_setups(self, setup_id_one, setup_id_two):

		"""
		gets pairwise shift setups		

		"""

		pairwise_shift_dict = self.get_pairwise_shift_dict(setup_id_one, setup_id_two)

		if pairwise_shift_dict is None:
			return None
		else:
			return pairwise_shift_dict['setup a'], pairwise_shift_dict['setup b']

		
	def get_pairwise_shift_matrix(self, setup_id_a, setup_id_b, square=False):

		"""
		gets pairwise shift matrix		

		"""

		pairwise_shift_dict = self.get_pairwise_shift_dict(setup_id_a, setup_id_b)

		if pairwise_shift_dict is None:
			return None
		else:
			
			pairwise_shift_matrix = pairwise_shift_dict['shift']

			if square:
				pairwise_shift_matrix = np.vstack((pairwise_shift_matrix,[0,0,0,1]))

			return pairwise_shift_matrix

	def get_pairwise_shift_bounding_box(self, setup_id_a, setup_id_b):

		"""
		gets pairwise shift matrix		

		"""

		pairwise_shift_dict = self.get_pairwise_shift_dict(setup_id_a, setup_id_b)

		if pairwise_shift_dict is None:
			return None
		else:
			bbs = pairwise_shift_dict['bounding box']
			return {'left':bbs[0], 'right':bbs[3], 'top':bbs[1], 'bottom':bbs[4], 'front':bbs[2], 'back':bbs[5]}


	def get_correlation(self, setup_id_a, setup_id_b):

		"""
		gets pairwise shift, order of setups is ignored
	
		"""
		
		pairwise_shift_dict = self.get_pairwise_shift_dict(setup_id_a, setup_id_b)

		if pairwise_shift_dict is None:
			return None
		else:
			return pairwise_shift_dict['correlation']


	def get_transform(self, setup_id, transform_type, *, square=False):

		"""
		gets transform matrix for volume	

		"""

		# allow setup_id to be volume_id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		# make sure transform name is valid
		if transform_type not in ['translation', 'stitching', 'calibration']:
			exit('Error: Transform type not valid...')

		# make sure transform is in xml
		if transform_type not in self.transforms[setup_id]:
			return None

		matrix = self.transforms[setup_id][transform_type]
		
		if square:
			matrix = np.vstack((matrix,[0,0,0,1]))

		return {'matrix':matrix, 'x':matrix[0,-1], 'y':matrix[1,-1], 'z':matrix[2,-1]}


	def get_volume_size(self, setup_id):

		"""
		gets voxel size for specific setup id

		"""

		# allow setup_id to be volume_id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)
	
		volume_size = self.setups[setup_id]['volume size']

		return {'size':volume_size, 'x':volume_size[0], 'y':volume_size[1], 'z':volume_size[2]}


	def get_voxel_size(self, setup_id):

		"""
		gets voxel size for specific setup id

		"""

		# allow setup_id to be volume_id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)
	
		voxel_size = self.setups[setup_id]['voxel size']

		return {'size':voxel_size, 'x':voxel_size[0], 'y':voxel_size[1], 'z':voxel_size[2]}


	def set_translation_to_grid_matrix(self, setup_id, value, dim):

		"""
		sets translation to grid matrix element for specific setup

		"""

		# allow setup_id to be volume_id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		if dim not in ['x', 'y', 'z']:
			exit('Error: dim is not valid...')
	
		if dim == 'x':	
			self.transforms[setup_id]['translation'][0,-1] = value
		elif dim == 'y':
			self.transforms[setup_id]['translation'][1,-1] = value
		elif dim == 'z':
			self.transforms[setup_id]['translation'][2,-1] = value


	def correlations_to_2d_list(self, dim):

		"""
		arranges all correlations into 2d list

		"""

		if dim not in ['x', 'y', 'xy']:
			exit('Error: dim is not valid...')

		# set bounds for iteration based on dimension
		if dim == 'y' or dim == 'xy':
			end_z_index = self.num_z_volumes
			end_y_index = self.num_y_volumes + 1
		elif dim == 'x':
			end_z_index = self.num_z_volumes + 1
			end_y_index = self.num_y_volumes

		# list to store correlations
		correlations = []

		# iterate through volumes
		for z in range(1,end_z_index):
			correlations_row = []
			for y in range(1,end_y_index):

				# get setup id for current volume
				setup_id = self.zy_to_setup_id(z,y)

				# get adjancet setup ids
				setup_ids_adjacent = self.adjacent_volumes_setup_id(setup_id)
	
				# get correlation for volumes
				if dim == 'xy':
					correlations_row.append(self.get_correlation(setup_id, setup_ids_adjacent['below right']))
					correlations_row.append(self.get_correlation(setup_id, setup_ids_adjacent['below left']))
				elif dim == 'y':
					correlations_row.append(self.get_correlation(setup_id, setup_ids_adjacent['below']))
				elif dim == 'x':
					correlations_row.append(self.get_correlation(setup_id, setup_ids_adjacent['left']))	

			# reverse order to match grid orientation
			correlations_row.reverse()
			
			# append to correlations
			correlations.append(correlations_row)

		return correlations


	def data_grid_to_string(self, dim, data_type):
	
		"""
		converts data grid into string for display

		"""

		if data_type not in ['correlation', 'transform overlap', 'pairwise overlap']:
			exit('Error: data type is not valid!')


		# header
		title_string = dim + ' ' + data_type + 's'
		data_string = '\n\n'+('#'*len(title_string))+'\n'
		data_string += title_string +'\n'
		data_string += ('#'*len(title_string))+'\n\n'	
	
		# get data
		if data_type == 'correlation':
			data = self.correlations_2d[dim]
		elif data_type == 'transform overlap':
			data = self.transform_overlaps_2d[dim]
		elif data_type == 'pairwise overlap':
			data = self.pairwise_overlaps_2d[dim]

		# index row on top
		data_string += '     '
		for i in range(len(data[0])):
			
			index = len(data[0])-i
			if dim == 'zy':
				index /= 2
				if i % 2 == 1:
					index = index+.5
			index = int(index)
			
			if index < 10:
				data_string += ' '
			data_string += '('+str(index) + ') '

		data_string += '\n\n'

		# iterate through rows of correlation grid
		for i, data_row in enumerate(data, start=1):

			# index column on left
			data_string += '('+str(i)+') '
	
			# add extra space for single digits
			if i < 10:
				data_string += ' '

			# iterate through cols
			for data_value in data_row:

				# format correlation
				data_value_string = self.format_data_value_for_grid(data_value)

				# append to row
				data_string += data_value_string + ' '

			data_string += '\n'

		return data_string


	def correlations_to_1d_list(self, dim):

		"""
		stores all correlations in dict where keys are adjacency type and values are sorted lists of correlations
	
		"""
		
		correlations = []	

		# iterate through pairwise shifts to get correlation
		for _, pairwise_shift in self.pairwise_shifts.items():

			adjacency_type = self.get_adjacency_type(pairwise_shift['setup a'], pairwise_shift['setup b'])
			
			if adjacency_type == dim:
				correlations.append(pairwise_shift['correlation'])

		# sort
		correlations.sort()
		correlations.reverse()

		return correlations


	def correlation_lists_to_string(self):

		s =  '\n#############\n'
		s += 'Correlations\n'
		s += '#############\n\n'

		if show_lists:
			s += 'x correlations: ' + str(self.correlations_1d['x']) + '\n\n'
			s += 'y correlations: ' + str(self.correlations_1d['y']) + '\n\n'
			s += 'xy Correlations: ' + str(self.correlations_1d['xy']) + '\n\n'
			s += 'non adjacent Correlations: ' + str(self.correlations_1d['non adjacent']) + '\n\n'

		return s
		
	
	def get_adjacency_type(self, setup_id_a, setup_id_b):

		"""
		gets adjacency type between two setups
		possible return values: 'x', 'y', 'xy', 'non adjacent'

		"""
		
		z_a = self.setup_id_to_z(setup_id_a)
		y_a = self.setup_id_to_y(setup_id_a)
	
		z_b = self.setup_id_to_z(setup_id_b)
		y_b = self.setup_id_to_y(setup_id_b)
		
		if z_a == z_b and abs(y_a - y_b) == 1:
			return 'x'
		elif y_a == y_b and abs(z_a - z_b) == 1:
			return 'y'
		elif abs(y_a - y_b) == 1 and abs(z_a - z_b) == 1:
			return 'xy'
		else:
			return 'non adjacent'
		


	def transform_volume_coords(self, setup_id, coords, *, ignore_stitching=False, shift_matrix=None):

		"""
		transforms volume coordinates to big stitcher coordinates using transform matrices

		"""

		# ignore stitching matrix if given shift matrix
		if shift_matrix is not None:
			ignore_stitching = True

		# allow setup_id to be volume_id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		# get transform matrices
		transforms = self.get_all_transforms(setup_id, square=True)

		# transform coordinates
		transformed_coords = transforms['translation'] @ transforms['calibration'] @ np.concatenate((coords, [1])).reshape(-1,1)

		# only apply stitching if matrix exists and ignore_stitching flag is set to false
		if 'stitching' in transforms and not ignore_stitching:
			transformed_coords = transforms['stitching'] @ transformed_coords

		# apply shift matrix
		if shift_matrix is not None:
			transformed_coords = shift_matrix @ transformed_coords
		

		return transformed_coords.flatten()[:-1]

	
	def get_volume_bounds_in_stitching_coordinates(self, setup_id,*, ignore_stitching=False, shift_matrix=None):

		"""
		transforms the volume bounds to stitching coordinates

		"""

		# allow setup_id to be volume_id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		bounds = {}

		left_top_front = self.transform_volume_coords(setup_id, [0,0,0], ignore_stitching=ignore_stitching, shift_matrix=shift_matrix)

		right_bottom_back_volume_coords = [coord-1 for coord in self.get_volume_size(setup_id)['size']]
		right_bottom_back = self.transform_volume_coords(setup_id,right_bottom_back_volume_coords,ignore_stitching=ignore_stitching, shift_matrix=shift_matrix)

		bounds['left'] = left_top_front[0]
		bounds['right'] = right_bottom_back[0]
		bounds['top'] = left_top_front[1]
		bounds['bottom'] = right_bottom_back[1]
		bounds['front'] = left_top_front[2]
		bounds['back'] = right_bottom_back[2]

		return bounds
	

	
	def get_transform_overlap(self, setup_id_a, setup_id_b):


		"""
		gets overlap from transform matrices
			- y overlap (left and right)
			- z overlap (up and down)
			- x overlap (in and out)

		"""

		# make sure a is before b
		if setup_id_a > setup_id_b:
			temp = setup_id_b
			setup_id_b = setup_id_a
			setup_id_a = temp

		setup_a_bounds = self.get_volume_bounds_in_stitching_coordinates(setup_id_a)
		setup_b_bounds = self.get_volume_bounds_in_stitching_coordinates(setup_id_b)

		volume_size_a = self.get_volume_size(setup_id_a)

		overlap_x = np.round(100*((setup_b_bounds['right'] - setup_a_bounds['left']+1) / volume_size_a['x']),1)
		overlap_y = np.round(100*((setup_a_bounds['bottom'] - setup_b_bounds['top']+1) / volume_size_a['y']),1)
		overlap_z = np.round(100*((setup_b_bounds['back'] - setup_a_bounds['front']+1)/ (volume_size_a['z']*self.anisotropy_factor)),1)

		return {'x':overlap_x,'y':overlap_y, 'z':overlap_z}




	def get_pairwise_shift_overlap(self, setup_id_one, setup_id_two):


		"""
		- gets overlap from pairwise shift between two volumes
		- uses bounding box since, translation to grid matrix can be changed possibly
		- setup a is fixed,  b needs to be shifted
				
		"""
	
		# get pairwise shift matrix, if doesnt exits, return dict of None
		pairwise_shift_matrix = self.get_pairwise_shift_matrix(setup_id_one, setup_id_two, square=True)

		if pairwise_shift_matrix is None:
			return {'y':None, 'z':None, 'x':None}

		# get bounding box 
		pairwise_shift_bounding_box = self.get_pairwise_shift_bounding_box(setup_id_one, setup_id_two)

		# get setup ids from pairwise shift
		setup_id_a, setup_id_b = self.get_pairwise_shift_setups(setup_id_one, setup_id_two)

		# if volume before is not volume b, then need to invert shift
		if setup_id_b > setup_id_a:
			pairwise_shift_matrix = np.linalg.inv(pairwise_shift_matrix)

		# apply shift to bounding box coords that come from setup b (left, bottom , front)
		left_bottom_front = np.array([pairwise_shift_bounding_box['left'], pairwise_shift_bounding_box['bottom'], pairwise_shift_bounding_box['front'],1])
		left_bottom_front_shifted = (pairwise_shift_matrix @ left_bottom_front)[:-1]
	
		# get volume size
		volume_size_a = self.get_volume_size(setup_id_a)

		# get overlaps
		overlap_x = np.round(100*((pairwise_shift_bounding_box['right'] - left_bottom_front_shifted[0]) / volume_size_a['x']),1)
		overlap_y = np.round(100*((left_bottom_front_shifted[1] - pairwise_shift_bounding_box['top']) / volume_size_a['y']),1)
		overlap_z = np.round(100*((pairwise_shift_bounding_box['back'] - left_bottom_front_shifted[2])/ (volume_size_a['z']*self.anisotropy_factor)),1)

		return {'x':overlap_x, 'y':overlap_y, 'z':overlap_z}
		
		

	def arrange_overlaps_grid(self, dim, shift_type, sectioning=False):

		"""
		arranges overlaps into 2d grid and also returns 1d list

		"""
			
		# make sure shift type is valid
		if shift_type not in ['transform', 'pairwise']:
			exit('Error: Shift type is not valid!')

		# make sure dim is valid
		if dim not in ['x', 'y', 'z']:
			exit('Error: dim is not valid...')

		# ending indices to loop through
		if dim == 'y' or dim == 'z':
			end_z_index = self.num_z_volumes
			end_y_index = self.num_y_volumes + 1
		elif dim == 'x':
			end_z_index = self.num_z_volumes + 1
			end_y_index = self.num_y_volumes

		# lists to store all overlaps
		overlaps_1d, overlaps_2d = [], []
		
		# lists to store overlaps if sectioning
		if self.sectioning and (dim == 'y' or dim == 'z'):
			 overlaps_1d_not_sectioning, overlaps_1d_sectioning = [], []

		# iterate through volumes
		for z in range(1,end_z_index):
			overlaps_row = []
			for y in range(1,end_y_index):

				# get setup id for current volume
				setup_id = self.zy_to_setup_id(z,y)

				# get adjacent setup ids
				setup_ids_adjacent = self.adjacent_volumes_setup_id(setup_id)

				if shift_type == 'transform':
					if dim == 'x':
						overlaps_row.append(self.get_transform_overlap(setup_id, setup_ids_adjacent['left'])[dim])
					elif dim == 'y' or dim == 'z':
						overlaps_row.append(self.get_transform_overlap(setup_id, setup_ids_adjacent['below'])[dim])
				elif shift_type == 'pairwise':
					if dim == 'x':
						overlaps_row.append(self.get_pairwise_shift_overlap(setup_id, setup_ids_adjacent['left'])[dim])
					elif dim == 'y' or dim == 'z':
						overlaps_row.append(self.get_pairwise_shift_overlap(setup_id, setup_ids_adjacent['below'])[dim])

			# reverse order to match grid orientation
			overlaps_row.reverse()

			# append
			overlaps_2d.append(overlaps_row)
			overlaps_1d += overlaps_row

			# append for sectioning
			if self.sectioning and (dim == 'y' or dim == 'z'):
				if z % self.sectioning_interval == 0:
					overlaps_1d_sectioning += overlaps_row
				else:
					overlaps_1d_not_sectioning += overlaps_row
					
		# remove None and sort 1d list
		overlaps_1d = [overlap for overlap in overlaps_1d if overlap != None]
		overlaps_1d.sort()

		# sort for sectioning
		if self.sectioning and (dim == 'y' or dim == 'z'):
			overlaps_1d_sectioning = [overlap for overlap in overlaps_1d_sectioning if overlap != None]
			overlaps_1d_not_sectioning = [overlap for overlap in overlaps_1d_not_sectioning if overlap != None]
			overlaps_1d_sectioning.sort()
			overlaps_1d_not_sectioning.sort()
			overlaps_1d = {'all':overlaps_1d,'sectioning':overlaps_1d_sectioning, 'not sectioning':overlaps_1d_not_sectioning}
		
		return overlaps_1d, overlaps_2d

	def generate_report(self, show_lists=False):

		"""
		saves txt file with information about correlations and overlaps, will be saved in same directory as xml		

		"""

		# create out path with same name and .txt extension
		out_path = self.xml_path[:-4] + '.txt'
		
		# write to file
		with open(out_path, 'w') as fp:
			fp.write(self.__str__())
			fp.write(self.data_grid_to_string('x', 'correlation'))
			fp.write(self.data_grid_to_string('y', 'correlation'))
			fp.write(self.data_grid_to_string('xy', 'correlation'))
			fp.write(self.data_grid_to_string('x', 'transform overlap'))
			fp.write(self.data_grid_to_string('y', 'transform overlap'))
			fp.write(self.data_grid_to_string('z', 'transform overlap'))
			fp.write(self.data_grid_to_string('x', 'pairwise overlap'))
			fp.write(self.data_grid_to_string('y', 'pairwise overlap'))
			fp.write(self.data_grid_to_string('z', 'pairwise overlap'))

	def shift_lengths_to_string(self):

		"""
		returns string showing how many pairwise shifts		

		"""

		s =  '	# x: ' + str(len(self.correlations_1d['x'])) + '\n'
		s += '	# y: ' + str(len(self.correlations_1d['y'])) + '\n'
		s += '	# xy: ' + str(len(self.correlations_1d['xy'])) + '\n'
		s += '	# non adjacent: ' + str(len(self.correlations_1d['non adjacent'])) + '\n\n'
		
		return s


	def estimate_overlaps(self, *, middle_percentage=.6, set_overlaps_and_save=False):

		"""
		- estimates overlap percentages to be used for fusion
		- middle percentage specifies the percentage of overlaps to use		

		"""

		overlaps_dict = {}

		for dim, overlaps in self.pairwise_overlaps_1d.items():
				
			# overlaps will be a dict if sectioning
			if self.sectioning and (dim == 'y' or dim == 'z'):
				for sectioning_type, sectioning_type_overlaps in overlaps.items():
					num_outliers = int(np.round(len(sectioning_type_overlaps)*middle_percentage/2))
					middle_overlaps = sectioning_type_overlaps[num_outliers:len(sectioning_type_overlaps)-num_outliers]
					key = dim + ' ' + sectioning_type
					overlaps_dict[key] = np.array(middle_overlaps).mean().round(1)
			else:
				num_outliers = int(np.round(len(overlaps)*middle_percentage/2))
				middle_overlaps = overlaps[num_outliers:len(overlaps)-num_outliers]
				overlaps_dict[dim] = np.array(middle_overlaps).mean().round(1)

		if set_overlaps_and_save:

			self.set_translation_to_grid_overlaps(overlaps_dict)
			self.save_xml('estimate_overlaps')
			
		return overlaps_dict

	def remove_non_adjacent_pairwise_shifts(self, save=True):


		"""
		removes non adjacent pairwise shifts from xml
	
		"""
		
		# iterate through pairwise shifts in xml and collect all non adjacent pairwise shifts
		shifts_to_remove = []
		for pairwise_shift in self.root.iter('PairwiseResult'):

			setup_id_a = int(pairwise_shift.attrib['view_setup_a'])
			setup_id_b = int(pairwise_shift.attrib['view_setup_b'])

			if self.get_adjacency_type(setup_id_a, setup_id_b) == 'non adjacent':
				shifts_to_remove.append(pairwise_shift)
	
		# remove all non adjacent pairwise stitchings from xml
		for pairwise_shift in shifts_to_remove:
			self.root.find('StitchingResults').remove(pairwise_shift)
		

		print('# Non Adjacent Pairwise Shifts Removed: ', len(shifts_to_remove))

		if save:
			self.save_xml('removed_non_adjacent_pairwise_shifts')

	def update_transform_matrices_in_xml(self):
	
		"""
		updates transform matrices in xml from those in internal dictionary

		"""
		# set registrations

		for registration in self.root.iter('ViewRegistration'):
			
			setup_id = int(registration.attrib['setup'])


			for transform in registration.iter('ViewTransform'):
				
				name = transform.find('Name').text

				if name == 'Translation to Regular Grid':
					translation_matrix_node = transform.find('affine')
					translation_matrix = self.get_transform(setup_id,'translation')['matrix']
					translation_matrix_node.text = self.matrix_to_string(translation_matrix)
				
				if name == 'Stitching Transform' and self.get_transform(setup_id,'stitching') is not None:
					stitching_matrix_node = transform.find('affine')
					stitching_matrix = self.get_transform(setup_id,'stitching')['matrix']
					stitching_matrix_node.text = self.matrix_to_string(stitching_matrix)


	def save_xml(self, xml_name, write_stitching_transform=False):
		
		"""
		saves xml file with current tree
	
		"""

		dir_name = dirname(self.xml_path)
		out_path = join(dir_name ,xml_name + '.xml')

		print('saving xml:', out_path)

		self.tree.write(out_path)

	def set_translation_to_grid_overlaps(self, overlaps):
		
		"""
		- sets translation to grid matrices to specific overlap percentages
		- sets them in internal dictionary and then updates xml		

		"""

		# iterate through all volumes
		setup_id = 0
		while setup_id < self.num_volumes:

			# get y and z
			y = self.setup_id_to_y(setup_id)
			z = self.setup_id_to_z(setup_id)

			# get adjacent setups
			adjacent_setups = self.adjacent_volumes_setup_id(setup_id)
		
			# volume size
			volume_size = self.get_volume_size(setup_id)

			# calculate new y (left-right) coordinate (fix all Y01)
			if y > 1:

				volume_bounds_right = self.get_volume_bounds_in_stitching_coordinates(adjacent_setups['right'], ignore_stitching=True)
				x_overlap_pixels = volume_size['x']*overlaps['x']/100
				new_x = volume_bounds_right['left'] + x_overlap_pixels - volume_size['x']
				
				self.set_translation_to_grid_matrix(setup_id, new_x, 'x')

			# calculate new y and z coordinate (fix all Z01)
			if z > 1:

				volume_bounds_top = self.get_volume_bounds_in_stitching_coordinates(adjacent_setups['above'], ignore_stitching=True)
		
				if self.sectioning:

					if ((z-1) % self.sectioning_interval) == 0:
						y_overlap_pixels = volume_size['y']*overlaps['y sectioning']/100-1
						z_overlap_pixels = volume_size['z']*self.anisotropy_factor*overlaps['z sectioning']/100-1
					else:
						y_overlap_pixels =  volume_size['y']*overlaps['y not sectioning']/100-1
						z_overlap_pixels =  volume_size['z']*self.anisotropy_factor*overlaps['z not sectioning']/100-1
				else:
					y_overlap_pixels =  volume_size['y']*overlaps['y']/100-1
					z_overlap_pixels =  volume_size['z']*self.anisotropy_factor*overlaps['z']/100-1
			

				# y calculations
				new_y = volume_bounds_top['bottom'] - y_overlap_pixels
				self.set_translation_to_grid_matrix(setup_id, new_y, 'y')

				# z calculations
				new_z = volume_bounds_top['front'] + z_overlap_pixels - volume_size['z']*self.anisotropy_factor
				self.set_translation_to_grid_matrix(setup_id, new_z, 'z')

			setup_id += 1

		# update transforms in xml
		self.update_transform_matrices_in_xml()

	def merge_pairwise_shifts(self):

		"""
		- used during pairwise shifts pipeline in parallel processing	
		- copies all pairwise shifts from each sub folder to the main xml	
	
		"""


		# get directory name
		xml_dir = dirname(self.xml_path)

		# get pairwise shifts object in xml
		pairwise_shifts = self.root.find('StitchingResults')
		
		# iterate through z volumes
		for i in range(1,self.num_z_volumes):
			
			# path for local xml
			local_xml_path = join(xml_dir, 'pairwise_shifts','Z_' + str(i) + '_' + str(i+1),'translate_to_grid.xml')
			
			# local xml objext
			local_xml = StitchingXML(local_xml_path, sectioning = self.sectioning)
		
			for pairwise_shift_local in local_xml.root.iter('PairwiseResult'):

				# if first job write all shifts 
				# otherwise dont need to write x shifts from upper
				if i == 1:
					pairwise_shifts.append(pairwise_shift_local)
				else:

					# get setup ids
					setup_id_a = int(pairwise_shift_local.attrib['view_setup_a'])
					setup_id_b = int(pairwise_shift_local.attrib['view_setup_b'])
			
					if self.get_adjacency_type(setup_id_a,setup_id_b) == 'x':
						if setup_id_a >= i*self.num_y_volumes and setup_id_b >= i*self.num_y_volumes:
							pairwise_shifts.append(pairwise_shift_local)
					else:
						pairwise_shifts.append(pairwise_shift_local)

		# write xml
		out_path = join(xml_dir, 'pairwise_shifts.xml')
		self.tree.write(out_path)


	def calculate_fused_dimensions(self):
		
		"""
		Calculate dimensions of image in big stitcher for fusion

		"""

		x_mins, x_maxs = [], []
		y_mins, y_maxs = [], []
		z_mins, z_maxs = [], []
		
		# iterate through volumes 
		for setup_id in self.setups:

			# get bounds of volume
			bounds = self.get_volume_bounds_in_stitching_coordinates(setup_id)

			# append to lists
			x_mins.append(bounds['left'])
			x_maxs.append(bounds['right'])
			y_mins.append(bounds['top'])
			y_maxs.append(bounds['bottom'])
			z_mins.append(bounds['front'])
			z_maxs.append(bounds['back'])

		# get bounds
		x_min = self.bbox_rounding(min(x_mins))
		x_max = self.bbox_rounding(max(x_maxs))
		y_min = self.bbox_rounding(min(y_mins))
		y_max = self.bbox_rounding(max(y_maxs))
		z_min = self.bbox_rounding(min(z_mins))
		z_max = self.bbox_rounding(max(z_maxs))

		# get lengths
		x_length = x_max - x_min + 1
		y_length = y_max - y_min + 1
		z_length = z_max - z_min + 1

		
		return {'x':{'min':x_min,'max':x_max,'length':x_length},'y':{'min':y_min,'max':y_max,'length':y_length},'z':{'min':z_min,'max':z_max,'length':z_length}}


	def define_bounding_boxes_for_parallel_fusion(self, grid_size, downsampling):

		"""
		- defines bounding boxes for parallel fusion
		- grid will be grid_size x grid_size
	
		"""

		# get fused dimensions
		fused_dimensions = self.calculate_fused_dimensions()

		# split each dimensions into grid size, z is fixed
		x_coords = np.linspace(fused_dimensions['x']['min'], fused_dimensions['x']['max'], num=grid_size+1, dtype=int)
		y_coords = np.linspace(fused_dimensions['y']['min'], fused_dimensions['y']['max'], num=grid_size+1, dtype=int)

		bounding_boxes = []

		# iterate through coords and calculate organize bounding boxes
		
		for x_idx in range(len(x_coords)-1):
			for y_idx in range(len(y_coords)-1):
				
				
				bbox_mins = [x_coords[x_idx],y_coords[y_idx],fused_dimensions['z']['min']]
				bbox_maxs = [x_coords[x_idx+1],y_coords[y_idx+1],fused_dimensions['z']['max']]

				# need to add 1 to the min after first bbox
				if x_idx > 0:
					bbox_mins[0] += downsampling

				if y_idx > 0:
					bbox_mins[1] += downsampling

				bounding_boxes.append([bbox_mins, bbox_maxs])

		# write bounding boxes to xml
		bounding_boxes_node = self.root.find('BoundingBoxes')

		for i,bounding_box in enumerate(bounding_boxes, start=1):
			
			bbox_mins = ' '.join([str(x) for x in bounding_box[0]])
			bbox_maxs = ' '.join([str(x) for x in bounding_box[1]])

			bbox_element = ET.SubElement(bounding_boxes_node,'BoundingBoxDefinition')
			bbox_element.set('name','Bounding Box ' + str(i) )
			
			min_element = ET.SubElement(bbox_element, 'min')
			max_element = ET.SubElement(bbox_element, 'max')

			min_element.text = bbox_mins
			max_element.text = bbox_maxs

			
		# write xml
		xml_dir = dirname(self.xml_path)
		out_path = join(xml_dir, 'fusion_' + str(downsampling) + '_parallel','estimate_overlaps_bboxes_'+str(grid_size)+'.xml')
		self.tree.write(out_path)
		

	def get_bounding_box_after_pairwise_shift(self, setup_id_one, setup_id_two):


		"""
		- gets bounding box in big stitching coordinates after shift
		- forces setup b to be before setup a
		- setup a gets fixed, and setup b moves
				
		"""

		# allow input to be volume_id
		if str(setup_id_one).startswith('Z'):
			setup_id_one = self.volume_to_setup_id(setup_id_one)
		if str(setup_id_two).startswith('Z'):
			setup_id_two = self.volume_to_setup_id(setup_id_two)
	
		# get pairwise shift matrix, if doesnt exits, return dict of None
		pairwise_shift_matrix = self.get_pairwise_shift_matrix(setup_id_one, setup_id_two, square=True)

		if pairwise_shift_matrix is None:
			return {'y':None, 'z':None, 'x':None}

		# get setup ids from pairwise shift
		setup_id_a, setup_id_b = self.get_pairwise_shift_setups(setup_id_one, setup_id_two)

		# force volume b to be 'before' (above/right) volume a
		if setup_id_b > setup_id_a:
			pairwise_shift_matrix = np.linalg.inv(pairwise_shift_matrix)
			temp = setup_id_a
			setup_id_a = setup_id_b
			setup_id_b = temp

		# get stitching coordinate bounds of volumes
		a_bounds = self.get_volume_bounds_in_stitching_coordinates(setup_id_a, ignore_stitching=True)
		b_bounds = self.get_volume_bounds_in_stitching_coordinates(setup_id_b, ignore_stitching=True)

		# apply shifts to volume bounds of b
		left_bottom_front = np.array([b_bounds['left'], b_bounds['bottom'], b_bounds['front'],1])
		left_bottom_front_shifted = (pairwise_shift_matrix @ left_bottom_front)[:-1]

		right_top_back = np.array([b_bounds['right'], b_bounds['top'], b_bounds['back'],1])
		right_top_back_shifted = (pairwise_shift_matrix @ right_top_back)[:-1]
		
		# logic to get proper bounding box

		if self.get_adjacency_type(setup_id_a, setup_id_b) == 'x':

			# left and right adjacency
			
			# left and right is always same
			left = left_bottom_front_shifted[0]
			right = a_bounds['right']
		
			if left_bottom_front_shifted[1] <= left_bottom_front[1]:
				
				# setup b moved up
				top = a_bounds['top']
				bottom = left_bottom_front_shifted[1]
			else:

				# setup b moved down				
				top = right_top_back_shifted[1]
				bottom = a_bounds['bottom']

		elif self.get_adjacency_type(setup_id_a, setup_id_b) == 'y':

			# up and down adjacency
			
			if left_bottom_front_shifted[0] <= left_bottom_front[0]:
				
				# setup b moved left
				left = a_bounds['left']
				right = right_top_back_shifted[0]
			else:
				
				# setup b moved right
				left = left_bottom_front_shifted[0]
				right = a_bounds['right']

			# up and down is always same
			top = a_bounds['top']
			bottom = left_bottom_front_shifted[1]

		elif self.get_adjacency_type(setup_id_a, setup_id_b) == 'xy':

			# diagonal adjacency
			
			if (setup_id_a-self.num_y_volumes-1) == setup_id_b:

				# setup b is to the right
				left = left_bottom_front_shifted[0]
				right = a_bounds['right']
	
			elif (setup_id_a-self.num_y_volumes+1) == setup_id_b:
				
				# setup b is to the left
				left = a_bounds['left']
				right = right_top_back_shifted[0]

			else:
				exit('Error: xy adjacency issue')


			top = a_bounds['top']
			bottom = left_bottom_front_shifted[1]
			
		else:
			exit('Error: adjacency type is invalid')


		# logic for z is always the same
		if left_bottom_front_shifted[2] <= left_bottom_front[2]:
			# setup b moved out
			front = a_bounds['front']
			back = right_top_back_shifted[2]
		else:
			# setup b moved in
			front = left_bottom_front_shifted[2]
			back = a_bounds['back']

		return {'left':left, 'right':right, 'top':top,'bottom':bottom, 'front':front, 'back':back}


	def volume_coords_to_fused_oblique_coords(self, volume_coords, setup_id, downsampling):

		"""
		- Converts volume coordinates in specific volume into coordinates in fused oblique image
		- volume_coords are 0 indexed
		- setup_id can be setup id or volume id
		- downsmpling is factor by which data is downsampled
		

		"""

		# allow input to be volume_id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		# get dimensions of fused image
		fused_dims = self.calculate_fused_dimensions()
		fused_lengths = np.array([fused_dims['x']['length'],fused_dims['y']['length'],fused_dims['z']['length']])

		# transform to big stitcher coords
		big_stitcher_coords = self.transform_volume_coords(setup_id, volume_coords)

		# get coordinated in fused image by subtracting mins of fused dimensions
		fused_mins = np.array([fused_dims['x']['min'],fused_dims['y']['min'],fused_dims['z']['min']])
		fused_oblique_coords = big_stitcher_coords - fused_mins
	
		# preserve original anisotropy
		fused_oblique_coords[-1] /= self.anisotropy_factor
		fused_lengths[-1] = self.bbox_rounding(fused_lengths[-1]/self.anisotropy_factor)

		# downsample
		fused_oblique_coords = (fused_oblique_coords / downsampling).round().astype(int)
		fused_lengths = fused_lengths / downsampling
		fused_lengths = np.array([self.bbox_rounding(coord) for coord in fused_lengths])
		
		# coords and length should be float
		fused_oblique_coords = fused_oblique_coords.astype(float)

				
		return fused_oblique_coords, fused_lengths


	def stitching_coords_to_coronal_cropped_coords_fast(self, coords, *, downsampling=10, isotropic=True, shear_factor, cropping_coord):
	
		"""
		- Converts Big Stitcher coords into coronal cropped coords
		- Uses matrix multiplication
		- coords should be nx3 matrix

		"""

		# get dimensions of fused image
		fused_dims = self.calculate_fused_dimensions()

		# precalculate image sizes
		fused_lengths = np.array([fused_dims['x']['length'],fused_dims['y']['length'],fused_dims['z']['length']])
		fused_lengths[-1] = self.bbox_rounding(fused_lengths[-1]/self.anisotropy_factor) # preserve original anisotropy
		fused_lengths = fused_lengths / downsampling # dowsample
		fused_lengths = np.array([self.bbox_rounding(coord) for coord in fused_lengths])
		image_lengths_isotropic = np.array([fused_lengths[0]/self.anisotropy_factor,fused_lengths[1]/self.anisotropy_factor, fused_lengths[2]]).astype(int)
		image_lengths_isotropic = np.array([self.bbox_rounding(coord) for coord in image_lengths_isotropic])
		image_lengths_after_reslice =  image_lengths_isotropic[[1,2,0]]
		image_lengths_after_vertical_flip = copy.deepcopy(image_lengths_after_reslice)
		image_lengths_after_shear = copy.deepcopy(image_lengths_after_vertical_flip)
		image_lengths_after_shear[1] = (image_lengths_after_shear[1] + abs(shear_factor)*image_lengths_after_shear[0]).astype(int)
		image_lengths_after_reslice_2 = image_lengths_after_shear[[1,2,0]]
		image_lengths_after_rotate = image_lengths_after_reslice_2[[1,0,2]]

		# define matrices
		subtract_min_matrix = np.array([[1,0,0,-fused_dims['x']['min']],[0,1,0,-fused_dims['y']['min']],[0,0,1,-fused_dims['z']['min']],[0,0,0,1]])		
		preserve_anisotropy_matrix = np.array([[1,0,0,0],[0,1,0,0],[0,0,1./self.anisotropy_factor,0],[0,0,0,1]])
		downsample_fusion_matrix = np.array([[1./downsampling,0,0,0],[0,1./downsampling,0,0],[0,0,1./downsampling,0],[0,0,0,1]])
		downsample_to_isotropic_matrix = np.array([[1./self.anisotropy_factor,0,0,0],[0,1./self.anisotropy_factor,0,0],[0,0,1,0],[0,0,0,1]])
		reslice_matrix = np.array([[0,1,0,0],[0,0,1,0],[1,0,0,0],[0,0,0,1]])
		vertical_flip_matrix = np.array([[1,0,0,0],[0,-1,0,image_lengths_after_reslice[1]-1],[0,0,1,0],[0,0,0,1]])
		x_shear = shear_factor
		shift_shear = -image_lengths_after_vertical_flip[1]/2 - shear_factor*image_lengths_after_vertical_flip[0]/2 + image_lengths_after_shear[1]/2 + 1
		shear_matrix = np.array([[1,0,0,0],[x_shear, 1, 0, shift_shear],[0,0,1,0],[0,0,0,1]])
		x_rotate = image_lengths_after_reslice_2[1] -1 
		rotate_matrix =  np.array([[0,-1,0,x_rotate],[1,0,0,0],[0,0,1,0],[0,0,0,1]])
		crop_shift_matrix = np.array([[1,0,0,0],[0,1,0,-cropping_coord],[0,0,1,0],[0,0,0,1]])


		# append row of 1s	
		coords = coords.T	
		ones = np.ones(shape=(1,coords.shape[1]))
		coords = np.vstack((coords,ones))

		# apply transformations
		out_coords = crop_shift_matrix @ rotate_matrix @ reslice_matrix @ shear_matrix @ vertical_flip_matrix @ reslice_matrix @ downsample_to_isotropic_matrix @ downsample_fusion_matrix @ preserve_anisotropy_matrix  @ subtract_min_matrix @ coords


		
		# clean up
		out_coords = out_coords[:-1].T.round().astype(int)

		return out_coords


	def volume_coords_to_coronal_cropped_coords(self, volume_coords, setup_id, *, downsampling=10, isotropic=True, shear_factor, cropping_coord):
		
		"""
		Converts volume coordinates to coronal cropped coordinates after fusion
		
		"""
	

		# coordinates after fusion
		fused_oblique_coords, fused_lengths = self.volume_coords_to_fused_oblique_coords(volume_coords, setup_id, downsampling)

		# make isotropic
		if isotropic:
			fused_oblique_coords[0] /= self.anisotropy_factor
			fused_oblique_coords[1] /= self.anisotropy_factor
			fused_oblique_coords = fused_oblique_coords.round().astype(int)

			fused_lengths[0] /= self.anisotropy_factor
			fused_lengths[1] /= self.anisotropy_factor
			fused_lengths = np.array([self.bbox_rounding(coord) for coord in fused_lengths])

			
		# perform transformations
		
		# reslice and vertical flip
		coords, image_lengths = self.reslice(fused_oblique_coords, fused_lengths)
		coords = self.vertical_flip(coords, image_lengths)


		# shear
		coords, image_lengths = self.shear(coords, image_lengths, shear_factor)

		# reslice
		coords, image_lengths = self.reslice(coords, image_lengths)

		# rotate 90 degrees
		coords, image_lengths = self.rotate(coords,image_lengths)

		# crop
		coords[1] -= cropping_coord

		return coords
		
	def transform_volume_coords_base(self, setup_id, coords, *, ignore_stitching=False, shift_matrix=None):

		"""
		Wrapper function for transforming volume coords

		"""

		if coords.ndim == 1:
			return self.transform_volume_coords(setup_id, coords, ignore_stitching=ignore_stitching, shift_matrix=shift_matrix)

		return self.transform_volume_coords_multiple(setup_id, coords, ignore_stitching=ignore_stitching, shift_matrix=shift_matrix)
		
	def inverse_transform_volume_coords_multiple(self, setup_id, coords, *, ignore_stitching=False, shift_matrix=None):

		"""
		transforms big stitcher coordinates to volume coordinates using transform matrices

		"""

		# ignore stitching matrix if given shift matrix
		if shift_matrix is not None:
			ignore_stitching = True

		# allow setup_id to be volume_id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		# get transform matrices
		transforms = self.get_all_transforms(setup_id, square=True)

		sh = np.shape(coords)
		transformed_coords = coords

		# apply shift matrix
		if shift_matrix is not None:
			transformed_coords = shift_matrix @ transformed_coords
		if 'stitching' in transforms and not ignore_stitching:
			transformed_coords = np.linalg.inv(transforms['stitching']) @ transformed_coords

		# transform coordinates
		transformed_coords = np.linalg.inv(transforms['calibration']) @ np.linalg.inv(transforms['translation']) @ np.transpose(np.hstack((coords, np.ones((sh[0],1)))))

		# only apply stitching if matrix exists and ignore_stitching flag is set to fals
		
		transformed_coords = np.transpose(transformed_coords)
		return transformed_coords[:,:-1]

	def transform_volume_coords_multiple(self, setup_id, coords, *, ignore_stitching=False, shift_matrix=None):

		"""
		transforms volume coordinates to big stitcher coordinates using transform matrices

		"""

		# ignore stitching matrix if given shift matrix
		if shift_matrix is not None:
			ignore_stitching = True

		# allow setup_id to be volume_id
		if str(setup_id).startswith('Z'):
			setup_id = self.volume_to_setup_id(setup_id)

		# get transform matrices
		transforms = self.get_all_transforms(setup_id, square=True)

		sh = np.shape(coords)

		# transform coordinates
		transformed_coords = transforms['translation'] @ transforms['calibration'] @ np.transpose(np.hstack((coords, np.ones((sh[0],1)))))

		# only apply stitching if matrix exists and ignore_stitching flag is set to false
		if 'stitching' in transforms and not ignore_stitching:
			transformed_coords = transforms['stitching'] @ transformed_coords

		# apply shift matrix
		if shift_matrix is not None:
			transformed_coords = shift_matrix @ transformed_coords
		
		transformed_coords = np.transpose(transformed_coords)
		return transformed_coords[:,:-1]


	def modify_image_loader_for_saving_as_n5(self):

		"""
		Modifies XML image loader to be compatible with N5

		"""
		
		# get image loader element
		imageLoader = self.root.find('SequenceDescription').find('ImageLoader')

		# set attributes
		imageLoader.set('format','bdv.n5')
		imageLoader.set('version','1.0')

		# remove all children elements
		children = []
		for child in imageLoader:
			children.append(child)
		for child in children:
			imageLoader.remove(child)

		# add n5 child element
		n5Child = ET.SubElement(imageLoader,'n5')
		n5Child.set('type','relative')
		n5Child.text = 'dataset.n5'

		# save xml
		self.save_xml('translate_to_grid')

	def __str__(self):

		s = '\n###############\n'
		s += 'Stitching Info\n'
		s += '###############\n\n'
		s += 'XML Path: ' + self.xml_path + '\n'
		s += '# Volumes: ' + str(self.num_volumes) + '\n'
		s += '	# Y: ' + str(self.num_y_volumes) + '\n'
		s += '	# Z: ' + str(self.num_z_volumes) + '\n'
		s += 'Voxel Size: ' + str(self.voxel_size) + '\n'
		s += 'Volume Size: ' + str(self.volume_size) + '\n'
		s += 'Anisotropy Factor: ' + str(self.anisotropy_factor) + '\n'
		s += '# Pairwise Shifts: ' + str(len(self.pairwise_shifts)) + '\n'
		s += self.shift_lengths_to_string()
		
		return s



##################################### to fix ##################################


	def getCoordsAdjacentVolume(self, sourceVolume, imageCoordsSource, targetVolume):
		
		"""
		- Given an image coordinate in source volume, uses pairwise shift to calculate 
		corresponding image cooridnate in target volume

		"""

		# get setup IDs
		setupIDSource = self.volumeToSetupID(sourceVolume)
		setupIDTarget = self.volumeToSetupID(targetVolume)

		# get pairwise shift
		pairwiseStitching = self.getPairwiseStitching(setupIDSource, setupIDTarget)

		shiftMatrix = np.vstack((pairwiseStitching['shift'],[0,0,0,1]))
		bbox = pairwiseStitching['bbox']
		correlation = pairwiseStitching['correlation']

		# shift describes how setup b should move
		viewSetupA = pairwiseStitching['setupID_a']
		viewSetupB = pairwiseStitching['setupID_b']

		# invert shift if volume are swapped	
		# since shift is how to go from view_setup b to view setup a
		# so source volume must be view setup b
		if setupIDSource != viewSetupB:
			shiftMatrix = np.linalg.inv(shiftMatrix)

		calibrationMatrix = self.getCalibrationMatrix(setupIDSource, square=True)
		translationMatrixSource = self.getTranslationToGridMatrix(setupIDSource, square=True)
		translationMatrixTarget = self.getTranslationToGridMatrix(setupIDTarget, square=True)
		
		# transform coords
		imageCoordsSource = np.append(np.array(list(imageCoordsSource)),1).reshape(-1,1)
		gridCoordsSource = translationMatrixSource @ calibrationMatrix @ imageCoordsSource
		gridCoordsShifted = shiftMatrix @ gridCoordsSource

		imageCoordsTarget = np.linalg.inv(calibrationMatrix) @ np.linalg.inv(translationMatrixTarget) @ gridCoordsShifted

		imageCoordsTarget = np.round(imageCoordsTarget.flatten()[:-1])


		return imageCoordsTarget
		
	
	

	def fusedCoronalCoords_to_volume(self, coords):
	
		# iterate through all setups and get bounding box in coronal cropped
		minVolume = None
		minDist = np.Inf

		for setupID in self.setupsAndRegistrations:
			
			volume = self.setupIDtoVolume(setupID)
			volumeSize = np.array(self.getVolumeSize(setupID))
			

			# get center coords
			center = utils.volumeCoords_to_fusedCoronalCoords(volume,volumeSize/2, self, downsampling=10)
			print(center)
			input()
			dist = ((np.array(center) - np.array(coords))**2).sum()

			if dist < minDist:
				minDist = dist
				minVolume = volume
				

		return minVolume
					
	
