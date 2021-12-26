clc;
clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
input_image_path = '/data/elowsky/image_smoothing_data/PV-GFP-M2/fused_coronal_10x10x10_CROPPED.tif';
output_path =  '/data/elowsky/image_smoothing_data/PV-GFP-M2/';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% Controls length and width of rectangular filter %%%%%
x_center = 25; % numnber of pixels from center

x_width_in = 2;
x_width_out = 150;
y_width = 1; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath('/data/elowsky/STP/');
%imStack = imreadstack(input_image_path);
%[ySize,xSize,numSlices] = size(imStack)
[imStack, Nframes] = imread_big(input_image_path);

[ySize, xSize, numSlices] = size(imStack);


x_mid = round(xSize/2);
y_mid = round(ySize/2);

output_image = zeros(ySize,xSize,numSlices);

for i = 1:numSlices
    if mod(i, 100) == 0
	i
    end
	
    imSlice = double(imStack(:,:,i));

    % take FFT of image
    imFFT = fftshift(fft2(imSlice));
    
    imFFT(y_mid-y_width:y_mid+y_width,x_mid+x_center-x_width_in:x_mid+x_center+x_width_out) = 0;
    imFFT(y_mid-y_width:y_mid+y_width,x_mid-x_center-x_width_out:x_mid-x_center+x_width_in) = 0;

    recoveredImage = ifft2(ifftshift(imFFT));
    output_image(:,:,i) = abs(recoveredImage);
end

[path,name,ext] = fileparts(input_image_path);
fname_corrected = fullfile(output_path,[name '_removedStripes' ext]);

% deletes files if already exists
if exist(fname_corrected) == 2
    delete(fname_corrected)
end


imwritestack(uint16(output_image), fname_corrected);
