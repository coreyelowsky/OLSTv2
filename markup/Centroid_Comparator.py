import numpy as np
import sys
import matplotlib.pyplot as plt
from sklearn.metrics import pairwise_distances
from os.path import join

class Centroid_Comparator:

	def __init__(self,image_id, truth_path, predictions_path, out_path, max_dist_thresh=100, res_factors=[2.5,.37,.37]):
	
		self.image_id = image_id
		self.truth_path = truth_path
		self.predictions_path = predictions_path
		self.out_path = out_path
		self.max_dist_thresh = max_dist_thresh
		self.res_factors = res_factors

		self.load_centroids()

		self.precisions, self.recalls, self.fscores = [0], [0], [0]
		self.auc_precision, self.auc_recall, self.auc_fscore = 0, 0, 0

		self.false_positives, self.false_negatives, self.true_positives = {}, {}, {}

		print()
		print('####################')
		print('Centroid Comparator')
		print('####################')
		print()
		print('# Centroids (truth):', self.num_truth)
		print('# Centroids (predicted):', self.num_predictions)
		print()


	def um_dist(self, x, y):

		# params
		#	x : list of voxel coordinates in order (z,y,x)
		#	y : list of voxel coordinates in order (z,y,x)
		#
		# returns distance in microns between two voxel coordinates


		return np.sqrt(((np.array(x-y)*self.res_factors)**2).sum())


	def area_under_curve(self,x, normalize=True, spacing=1):
	
		# params
		#	x : list of metric calculated at various thresholds
		#	normalize : if True, normalize between 0 and 1
		#	spacing : spacing between distance thresholds

		if normalize:
			return np.sum(x[1:]*spacing)/(len(x)-1)
		else:
			return np.sum(x[1:]*spacing)
	

	def load_centroids(self):

		# load centroid csvs
		
		try:
			self.truth_centroids = np.genfromtxt(join(self.truth_path,self.image_id+'_CENTROIDS.csv'),delimiter=',')[:,:3]
		except OSError as err:
			print('Error:',err)
			sys.exit()
		
		try:	
			self.prediction_centroids = np.genfromtxt(join(self.predictions_path,self.image_id+'_CENTROIDS.csv'),delimiter=',')[:,:3]
		except OSError as err:
			print('Error:',err)
			sys.exit()

		self.num_truth = len(self.truth_centroids)
		self.num_predictions = len(self.prediction_centroids)


	def calculate_metrics(self):
	
		print('Calculating Metrics...')
		print()
		
		# calculates precision, recall, and fscore for varying distance thresholds

		self.precisions, self.recalls, self.fscores = [0], [0], [0]
		self.false_positives, self.false_negatives, self.true_positives = {}, {}, {}

		# iterate through distance thresholds
		for dist_thresh in range(1,self.max_dist_thresh + 1):

			# calculate pairwise distances matrix
			distances = pairwise_distances(self.truth_centroids,self.prediction_centroids,metric=self.um_dist)

			
			# lists to hold indices of fp, fn, tp
			fn_indices = np.arange(self.num_truth)
			fp_indices = np.arange(self.num_predictions)
			tp_indices = []

			while len(distances)  > 0:

				# find minimum pairwise distances matching indices
				# if more than one pair, choose first
				min_dist = np.min(distances)
				row_min,col_min = np.argwhere(distances == min_dist)[0]

				# check if distance is below threshold
				# if so, count pair as true positive and delete row and column from distances matrix
				# othewise if not below threshold all remaining centroids left are false negatives or false positives
				if min_dist < dist_thresh:

					# add to true positives
					tp_indices.append([fn_indices[row_min],fp_indices[col_min]])

					# delete from fn and fp indices arrays
					fn_indices = np.delete(fn_indices, row_min)
					fp_indices = np.delete(fp_indices, col_min)

					# edge cases if distances matrix is only one dimension
					# if this occurs break
					if distances.shape[0] == 1 or distances.shape[1] == 1:
						break

					# delete row and column
					distances = np.delete(distances, row_min ,axis=0)
					distances = np.delete(distances, col_min, axis=1)

				else:
					# only reaches here once when no more pairwise distances are below threshold	
					# only need to break
					break

			# populate fp,fn,tp dictionaries
			self.false_positives[dist_thresh] = fp_indices
			self.false_negatives[dist_thresh] = fn_indices
			self.true_positives[dist_thresh] = np.array(tp_indices)

			tp = len(tp_indices)
			fp = len(fp_indices)
			fn = len(fn_indices)

			# calculate metrics
			precision = tp / (tp + fp)
			recall = tp / (tp + fn)
			fscore = (2*tp) / (2*tp + fp + fn)
	
			# append to global lists
			self.precisions.append(precision)
			self.recalls.append(recall)
			self.fscores.append(fscore)

			# Error check to make sure counts add up 
			if (2*tp+fp+fn) != (len(self.truth_centroids) + len(self.prediction_centroids)):
				sys.exit('Error: counts dont add up')

		# calculate area under curves
		self.auc_precision = self.area_under_curve(self.precisions)
		self.auc_recall = self.area_under_curve(self.recalls)
		self.auc_fscore = self.area_under_curve(self.fscores)

		print('Precision (AUC):', np.round(self.auc_precision,3))
		print('Recall (AUC):', np.round(self.auc_recall,3))
		print('F-Score (AUC):', np.round(self.auc_fscore,3))
		print()

	def save_results(self, distance_thresh):

		# params
		#	distance_thresh : distance threshold to save results for

		out_path = join(self.out_path,'comparison_results_' + self.image_id + '_distancethresh_' + str(distance_thresh)+'.txt')
		print('Saving Metrics to:',out_path)

		fp_coords = self.prediction_centroids[self.false_positives[distance_thresh]][:,[2,1,0]]
		fn_coords = self.truth_centroids[self.false_negatives[distance_thresh]][:,[2,1,0]]
		
		tp_coords_truth =  self.truth_centroids[self.true_positives[distance_thresh][:,0]][:,[2,1,0]]
		tp_coords_predictions =  self.prediction_centroids[self.true_positives[distance_thresh][:,1]][:,[2,1,0]]

		with open(out_path,'w') as fp:
			fp.write('Image ID: '+ self.image_id +'\n')
			fp.write('Truth Path: ' + self.truth_path + '\n')
			fp.write('Prediction Path: ' + self.predictions_path + '\n\n')
			fp.write('Distance Threshold: ' + str(distance_thresh) + ' um\n')
			fp.write('Precision: ' + str(np.round(self.precisions[distance_thresh],3)) + '\n')
			fp.write('Recall: ' + str(np.round(self.recalls[distance_thresh],3)) + '\n')
			fp.write('F-Score: ' + str(np.round(self.fscores[distance_thresh],3)) + '\n\n')
			fp.write('False Positives: ' + str(len(fp_coords))  + '\n\n')
			fp.write(str(fp_coords))
			fp.write('\n\n')
			fp.write('False Negatives: ' + str(len(fn_coords)) + '\n\n')
			fp.write(str(fn_coords))
			fp.write('\n\n')
			fp.write('True Positives (Truth - Prediction - Distance (um)): '+str(len(tp_coords_truth)) +'\n\n')
			for t,p in zip(tp_coords_truth, tp_coords_predictions):
				fp.write(str(t) + ' ' + str(p) + ' ' + str(np.round(self.um_dist(t[::-1],p[::-1]),1)) +  '\n')
			
			

	def plot_results(self,save=False):

		fig, ax = plt.subplots(1,3)

		dist_threshes = np.arange(self.max_dist_thresh+1)

		ax[0].plot(dist_threshes,self.precisions)
		ax[0].set_title('Precision: ' + str(np.round(self.auc_precision,3)))
		ax[0].set_ylim([0,1])
		ax[1].plot(dist_threshes,self.recalls)
		ax[1].set_title('Recall: ' + str(np.round(self.auc_recall,3)))
		ax[1].set_xlabel('Distance Threshold (um)')
		ax[1].set_ylim([0,1])
		ax[1].set_yticks([])
		ax[2].plot(dist_threshes,self.fscores)
		ax[2].set_title('F-score: ' + str(np.round(self.auc_fscore,3)))
		ax[2].set_ylim([0,1])
		ax[2].set_yticks([])

		# global title
		fig = plt.gcf()
		fig.suptitle(self.image_id, fontsize=14, fontweight='bold')
	
		# either save or show
		if save:
			out_path = join(self.out_path,self.image_id+'.png')
			print('Saving Metrics Figure to:',out_path)
			print()
			plt.savefig(out_path)
		else:	
			plt.show()


if __name__ == '__main__':

	image_id = 'Z02_Y08_1707'
	truth_path = '/data/elowsky/OLST_2/markup/ground_truth_gold_standard/'
	predictions_path = '/data/elowsky/OLST_2/markup/ground_truth_initial_markup_rhonda/'
	out_path = '/data/elowsky/OLST_2/markup/ground_truth_gold_standard/'

	c = Centroid_Comparator(image_id, truth_path, predictions_path, out_path)
	c.calculate_metrics()
	c.save_results(distance_thresh=50)
	#c.plot_results(save=False)
	











	
