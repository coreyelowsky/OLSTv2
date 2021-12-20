from os.path import join
from os import listdir
import numpy as np
from statistics import median

# find max time for parallel fusion

downsampling = 16

input_dir = '/mnt/nfs/grids/hpc_norepl/elowsky/PV-GFP-M2/fusion_'+str(downsampling)+'_parallel/'

log_dir = join(input_dir,'logs')


log_names = [x for x in listdir(log_dir) if 'parallel.o' in x]

times = []

for log_name in log_names:
	with open(join(log_dir,log_name)) as f:
		for line in f:
			if 'seconds' in line or 'minutes' in line or 'hours' in line or 'days' in line:
				time_line = line
				break
		time = float(line.split(' ')[3])
		unit = line.split(' ')[4]

		# convert to seconds
		if 'minutes' in unit:
			time *= 60
		if 'hours' in unit:
			time *= 60*60
		if 'days' in unit:
			time *= 60*60*24

		times.append(time)

times = np.array(times)
print('# Jobs:', len(times))

mean_time = median(times)
max_time = max(times)

unit = 'seconds'
if 60 <= max_time < 60*60:
	max_time /= 60
	unit = 'minutes'
elif 60*60 <= max_time <  60*60*24:
	max_time /= 60*60
	unit = 'hours'
elif max_time >= 24*60*60:
	max_time /= 24*60*60
	unit = 'days'

unit_mean = 'seconds'
if 60 <= mean_time < 60*60:
	mean_time /= 60
	unit_mean = 'minutes'
elif 60*60 <= max_time <  60*60*24:
	mean_time /= 60*60
	unit_mean = 'hours'
elif mean_time >= 24*60*60:
	mean_time /= 24*60*60
	unit_mean = 'days'

print('Median:', mean_time.round(1), unit_mean)
print('Max:', max_time.round(1), unit)
		
	






