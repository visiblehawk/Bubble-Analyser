%Template image processing algorithm coming with Bubble Analyser software
%
% Syntax: FourierMethod(I, params)
%
% Inputs:
%    I: image, either rgb or grayscale
%    params: parameters needed for certain operations, either set by the
%    user or in the corresponding .config file
%    
% Outputs:
%    D: number array with the equivalent diameter, in mm, of each bubble detected and segmented
%    L: labelled image resulting from the image processing algorithm
%    extra_info: structure containing extra information about bubbles
%    (eccentricity, solidity, etc)
%
%
% Author: Reyes, Francisco; Quintanilla, Paulina; Mesa, Diego
% email: f.reyes@uq.edu.au,  
% Website: https://gitlab.com/frreyes1/bubble-sizer
% Copyright Feb-2021;
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
bknd_img = params.background_img;
do_batch = params.do_batch; %Check if we are doing batch processing or justone image

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

[M,N] = size(B);
% Apply zero padding for unequal dimensions
diff = abs(M-N);  % difference of rows and columns numbers

if M > N                           % More rows than columns
    if (mod(diff,2) == 0)          % Even difference
        imgB =  [zeros(M, diff/2) B zeros(M, diff/2)];       % Add columns to match dimensions
    else                           % Odd difference
        imgB = [zeros(M, floor(diff/2)) B zeros(M, floor(diff/2) + 1)];
    end
elseif M < N                       % More columns than rows
    if (mod(diff,2) == 0)          % Even difference
        imgB = [zeros(diff/2, N); B; zeros(diff/2, N)];         % Add rows to match dimensions
    else
        imgB = [zeros(floor(diff/2), N); B; zeros(floor(diff/2) + 1, N)];
    end
end


% Remove small objects < 100 pixels
im = bwareaopen(imgB, 100);
% Operate along the rows
im( ~any(im,2), : ) = [];  % Remove empty lines
[mx,nx] =size(im);
fft_x = fft(hamming(mx).*(im-mean(im,2)),[],2);% FFT along the rows
FourierMean_x = 20*log10(mean(abs(fft_x).^2, 1)); % Taking average along the y axis
FourierMean_x = FourierMean_x - max(FourierMean_x);
FourierMean_x = FourierMean_x(:, 1:nx/2); % Half the dimension due to symmetry

% Operate along the coloumns
im = bwareaopen(imgB, 100);
im( :, ~any(im,1) ) = [];  % Remove empty lines
[my,~] = size(im);
fft_y = fft(hamming(my).*(im-mean(im,1)),[],1);% FFT along the columns 
FourierMean_y = 20*log10(mean(abs(fft_y).^2, 2)); % Taking average along the x axis
FourierMean_y = FourierMean_y - max(FourierMean_y);
FourierMean_y = FourierMean_y(1:my/2, :); % Half the dimension due to symmetry


Fs = px2mm/img_resample;% Because we scaled down the image by some factor
freq = linspace(0, Fs/2, nx/2);


% Compute the average of all lines
FourierMean = [FourierMean_x', FourierMean_y];
Normalised_PSD = mean(FourierMean,2);

% Smooth the data
xq=freq(1):0.001:freq(end);
Normalised_PSD = pchip(freq,Normalised_PSD,xq); 
D32 = 3.7./xq.^1.1;

% Find the corresponding average D32 according to the bandwidth
[~,idx]=min(abs(Normalised_PSD-(-20)));
D = D32(idx);

extra_info = []; %nothing to include for now

if do_batch
    L_image = [];
else
  
     L_image = imresize(B, [n,m]);
end

