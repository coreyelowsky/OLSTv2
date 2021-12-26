#@ String inputPath
#@ String shearFile
#@ String outputPath

from transformj import TJ
from imagescience.transform import Affine
from imagescience.transform import Transform
from imagescience.image import Image
from ij import WindowManager
from ij import ImagePlus
from ij import IJ
import csv


print("Input Path:" + inputPath)
print("Shear File:" + shearFile)
print("Output Path:" + outputPath)


# open image
imp = IJ.openImage(inputPath)

# read shear matrix
shearMatrix = []
with open(shearFile, 'r') as f:
    reader = csv.reader(f)
    for row in reader:
        r = [float(x) for x in row[0].split('\t')]
	shearMatrix.append(r)

# instantiate affine transform object
affiner = Affine()

# wrap as image
image = Image.wrap(imp)

# parameters
transform = Transform(shearMatrix)
scheme = Affine.LINEAR
adjust=True
resample=False
antialias=False

# run affine transform
outputImage = affiner.run(image, transform, scheme, adjust, resample, antialias);

# wont display (source code modified)
# sets correct properties for image
impOut = TJ.show(outputImage, imp)

# save image
IJ.save(impOut, outputPath)

