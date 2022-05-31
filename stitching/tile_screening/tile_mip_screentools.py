# coding: utf-8

# In[1]:


#For screening tools for light sheet microscopy image tiles from Pavel lab


# In[2]:


from skimage import io
import os
import numpy
import pandas
import sys
import shutil

# In[3]:


# Here are the positive and negative MIP folders
positive_folder = sys.argv[1]
negative_folder = sys.argv[2]
#Here is the test folder from another brain
test_folder = sys.argv[3]


# In[4]:


# get the statistics for the 18 positive MIP samples
num_pos = len(os.listdir(positive_folder))
pos_data = numpy.array([])
pos_max_array = numpy.zeros(num_pos)
pos_mean_array = numpy.zeros(num_pos)
pos_std_array = numpy.zeros(num_pos)

index_p = 0
for filename in os.listdir(positive_folder):
    #print(filename)
    im = (io.imread(positive_folder+filename)).astype(float)
    
    if pos_data.size == 0:
        pos_data=im
        pos_max_array[0] = im.max()
        pos_mean_array[0] = im.mean()
        pos_std_array[0] = im.std()        
    else:
        pos_data=numpy.concatenate((pos_data, im), axis=0)
        pos_max_array[index_p] = im.max()
        pos_mean_array[index_p] = im.mean()
        pos_std_array[index_p] = im.std()
       
    index_p=index_p+1
    


# In[5]:


# get the statistics for the 18 negative MIP samples
num_neg = len(os.listdir(negative_folder))
neg_data = numpy.array([])
neg_max_array = numpy.zeros(num_neg)
neg_mean_array = numpy.zeros(num_neg)
neg_std_array = numpy.zeros(num_neg)

index_p = 0
for filename in os.listdir(negative_folder):
    #print(filename)
    im = (io.imread(negative_folder+filename)).astype(float)
    
    if neg_data.size == 0:
        neg_data=im
        neg_max_array[0] = im.max()
        neg_mean_array[0] = im.mean()
        neg_std_array[0] = im.std()        
    else:
        neg_data=numpy.concatenate((neg_data, im), axis=0)
        neg_max_array[index_p] = im.max()
        neg_mean_array[index_p] = im.mean()
        neg_std_array[index_p] = im.std()
       
    index_p=index_p+1
    


# In[6]:


# calculate the threshold assuming two Gaussian distribution for background and foreground
# same for Max,Mean and std
thres_max = neg_max_array.max() + (pos_max_array.max()-neg_max_array.max())*neg_max_array.std()/(neg_max_array.std()+pos_max_array.std())

thres_mean = neg_mean_array.mean() + (pos_mean_array.mean()-neg_mean_array.mean())*neg_mean_array.std()/(neg_mean_array.std()+pos_mean_array.std())

thres_std = neg_std_array.max() + (pos_std_array.max()-neg_std_array.max())*neg_std_array.std()/(neg_std_array.std()+pos_std_array.std())


# In[7]:


# display the values
thres_max


# In[8]:


thres_mean


# In[9]:


thres_std


# In[10]:


#Using Otsu to find a segmentation threshold for foreground(bright) pixels
from skimage import filters
thres_seg = filters.threshold_otsu(pos_data)
thres_seg


# In[11]:


# bright pixel number threshold as 0.2% of the volume voxels
thres_birght_pixel_num = (im.size*0.002) # actually 0<this<2% all works
thres_birght_pixel_num


# In[12]:


#Design: 
#Screen tool1: 'positive' if numpy.max(im)>thres_max else 'negative'  that is if maximum grayscale value larger than threshold, positive
#Screen tool2: 'positive' if numpy.mean(im)>thres_mean else 'negative' that is if mean of the grayscale values larger than threshold, positive
#Screen tool3: 'positive' if numpy.std(im)>thres_std else 'negative' that is if standard deviation of the grayscale values larger than threshold, positive
#Screen tool4: 'positive' if (im[im>thres_seg]).size>(im.size*0.01) else 'negative' that is if there are more than 0.2% of the volume voxels, consider this volumne as positive


# In[13]:


# Create the pandas DataFrame
df_s1234 = pandas.DataFrame(columns=['filename','category', 'max','mean','std', 'number>thresh','S1_max','S2_mean','S3_std','S4_seg'])
# Here first two columns are filename and if category is known
# then four columns of measurements: max, mean, std and number of pixels with grayscale larger than threshold
# the last t=four columns are the four screening tool results

# Start testing with positive folder
for filename in os.listdir(positive_folder):
    # for each MIP tiff in the folder, read in and get the values and judgements
    im = (io.imread(positive_folder+filename)).astype(float)
    data=[filename,'positive',numpy.max(im),round(numpy.mean(im),1),round(numpy.std(im),1),(im[im>thres_seg]).size,
          'positive' if (numpy.max(im))>thres_max else 'negative', 'positive' if numpy.mean(im)>thres_mean else 'negative', 
          'positive' if numpy.std(im)>thres_std else 'negative', 'positive' if (im[im>thres_seg]).size>thres_birght_pixel_num else 'negative']
    #df_s1234.loc[len(df_s1234)]=data
    
# Start testing with negative folder
for filename in os.listdir(negative_folder):
    im = (io.imread(negative_folder+filename)).astype(float)
    data=[filename,'negative',numpy.max(im),round(numpy.mean(im),1),round(numpy.std(im),1),(im[im>thres_seg]).size,
          'positive' if (numpy.max(im))>thres_max else 'negative', 'positive' if numpy.mean(im)>thres_mean else 'negative', 
          'positive' if numpy.std(im)>thres_std else 'negative', 'positive' if (im[im>thres_seg]).size>thres_birght_pixel_num else 'negative']
    #df_s1234.loc[len(df_s1234)]=data
        


# In[14]:
pos_tiles = list()

# Start testing with new testing folder from a second brain
for filename in os.listdir(test_folder):
    print('Processing file ' + filename, flush=True)
    im = (io.imread(test_folder+filename)).astype(float)
    if im.ndim == 3:
        im = numpy.max(im, axis=0)
    num_pos_criteria = 0
    if (numpy.max(im))>thres_max:
        num_pos_criteria = num_pos_criteria + 1
    if numpy.mean(im)>thres_mean:
        num_pos_criteria = num_pos_criteria + 1
    if numpy.std(im)>thres_std:
        num_pos_criteria = num_pos_criteria + 1
    if (im[im>thres_seg]).size>thres_birght_pixel_num:
        num_pos_criteria = num_pos_criteria + 1
    
    if num_pos_criteria >= 3:
        outcome = 'positive'
        pos_tiles.append(filename)
    elif num_pos_criteria >= 1:
        outcome = 'other'
    else:
        outcome = 'negative'

    data=[filename,outcome,numpy.max(im),round(numpy.mean(im),1),round(numpy.std(im),1),(im[im>thres_seg]).size,
          'positive' if (numpy.max(im))>thres_max else 'negative', 'positive' if numpy.mean(im)>thres_mean else 'negative', 
          'positive' if numpy.std(im)>thres_std else 'negative', 'positive' if (im[im>thres_seg]).size>thres_birght_pixel_num else 'negative']
    df_s1234.loc[len(df_s1234)]=data
    
    


# In[15]:

df_sorted = df_s1234.sort_values(by = ['category', 'filename'], ascending = [True, True])
df_sorted.to_csv(sys.argv[4])


# In[16]:
has_max_prefix = True
if sys.argv[5] == sys.argv[3]:
    has_max_prefix = False
for f in pos_tiles:
    f2 = f
    if has_max_prefix:
        f2 = f[4:]
    shutil.copy(os.path.join(sys.argv[5], f2), os.path.join(sys.argv[6], f2))

# Final tools for positives:
# Screen tool1: numpy.max(im)>3992 
# Screen tool2: numpy.mean(im)>240
# Screen tool3: numpy.std(im)>181 
# Screen tool4: (im[im>2836]).size>(im.size*0.01) 


# In[ ]:




