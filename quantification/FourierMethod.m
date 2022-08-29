%Image analysis method based on 
%	Vinnett et al. An image analysis approach to determine average bubble sizes using one-dimensional
%	Fourier analysis. 2018. Minerals Engineering 126:160-166. 10.1016/j.mineng.2018.06.030
%
% Syntax: FourierMethod(I, params)
%
% Inputs:
%    I: image, either rgb or grayscale
%    params: parameters needed for certain operations, either set by the
%    user or in the corresponding .config file
%    
% Outputs:
%    D: number array with the Sauter diameter, in mm, of the input image
%    L: BW image showing the bubble segmentation
%    extra_info: nothing for now
%
%
% Author: Yunhao Guan 
% email: yunhao.guan20@imperial.ac.uk,  
% Website: https://gitlab.com/frreyes1/bubble-sizer
% Copyright Aug-2022;
%
%This file is part of Bubble Analyser.
%
%    Bubble Analyser is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation version 3 only of the License.
%
%    Bubble Analyser is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with Bubble Analyser. If not, see <https://www.gnu.org/licenses/>.
%
%------------- BEGIN CODE --------------
function [D, L_image, extra_info] = FourierMethod(img, params)

%Collect parameters from the structure
se = strel('disk', params.Morphological_element_size); %strel object to perform binary operations;
px2mm = params.px2mm; %img resolution
img_resample = params.resample;
min_size = params.min_size * img_resample;
bknd_img = params.background_img;
do_batch = params.do_batch; %Check if we are doing batch processing or just one image

%Resize images for making processing faster
[n, m, k] = size(img);
img = imresize(img, img_resample); %resample img to make process faster
if k>1
    img = rgb2gray(img);
end

%use background correction to help the gray threshold
if ~isempty(bknd_img)
    if size(bknd_img,3)>1
        bknd_img = rgb2gray(bknd_img);
    end
    T = adaptthresh(bknd_img, 0.4 , 'ForegroundPolarity', 'dark');
end
if ~isempty(bknd_img)
    BW = imbinarize(img,imresize(T, img_resample));
else
    BW = imbinarize(img);
end

%Use morphological operations to help make the bubbles solid
B = imclose(~BW,se);
B = imfill(B,'holes');

%Fourier method now. The idea is to analyse each row and column of the
%image and then average the Power Spectral Density.

%The FFT likes the signal to have a power of 2 dimension, let's make sure
%both columns and rows are equal to the nearest power of 2 number
[M, N] = size(B);
%nearest power of 2, greater than M and N
NPof2 = 2^nextpow2(max([M N]));

% Apply zero padding on both dimensions
diff = abs(NPof2-N);  % Columns to add
if (mod(diff,2) == 0)          % Even difference
    imgB =  [zeros(M, diff/2) B zeros(M, diff/2)];       % Add columns to match dimensions
else                           % Odd difference
    imgB = [zeros(M, floor(diff/2)) B zeros(M, floor(diff/2) + 1)];
end
diff = abs(NPof2-M);  % Rows to add
if (mod(diff,2) == 0)          % Even difference
    imgB = [zeros(diff/2, NPof2); imgB; zeros(diff/2, NPof2)];         % Add rows to match dimensions
else
    imgB = [zeros(floor(diff/2), NPof2); imgB; zeros(floor(diff/2) + 1, NPof2)];
end

% Remove small objects < min_size pixels
im = bwareaopen(imgB, min_size);
H = hamming(NPof2); %Hamming filter to avoid freq. leakage

% Operate along the rows
imx = im;
imx( ~any(imx,2), : ) = [];  % Remove empty lines
fft_x = fft(H'.*(imx-mean(imx,2)),[],2); % FFT along the rows, removing the continious component
avgPSD = mean(abs(fft_x).^2,1); % Taking average along the y axis
FourierMean_x = 10*log10(avgPSD/max(avgPSD)); %Normalise agaisnt maximum value
FourierMean_x = FourierMean_x(:, 1:NPof2/2); % Half the dimension due to symmetry

% Operate along the coloumns
imy = im;
imy(:, ~any(imy,1)) = [];  % Remove empty lines
fft_y = fft(H.*(imy-mean(imy,1)),[],1);% FFT along the columns
avgPSD = mean(abs(fft_y).^2,2); % Taking average along the y axis
FourierMean_y = 10*log10(avgPSD/max(avgPSD)); %Normalise agaisnt maximum value
FourierMean_y = FourierMean_y(1:NPof2/2, :); % Half the dimension due to symmetry

%get frequency scale
Fs = px2mm/img_resample;% Because we scaled down the image by some factor
%freq = linspace(0, Fs/2, NPof2/2);
freq_ax = 1/Fs/NPof2 *(0:NPof2-1) - 1/Fs/2; %Frequency axis, in [pxl/mm]
freq_ax = freq_ax(NPof2/2+1:end); % Half the dimension due to symmetry

% Compute the average of all lines
FourierMean = [FourierMean_x', FourierMean_y];
Normalised_PSD = mean(FourierMean,2);

% Smooth the data
xq = freq_ax(1):0.001:freq_ax(end);
Normalised_PSD = pchip(freq_ax,Normalised_PSD,xq); 

%transform into d32, according to the paper's findings
D32 = 3.7./xq.^1.1;

% Find the corresponding average D32 according to the bandwidth
[~,idx] = min(abs(Normalised_PSD-(-20)));
D = D32(idx);

extra_info = []; %nothing to include for now

if do_batch
    L_image = [];
else
  
     L_image = imresize(B, [n,m]);
end

