%Default image processing algorithm coming with Bubble Analyser software
%
% Syntax: PartialWatershed(I, params)
%
% Inputs:
%    img: image, either rgb or grayscale
%    params: parameters needed for certain operations, default values set by the
%    corresponding .config file, but can be edited by the user
%
% Outputs:
%    D: number array with the equivalent diameter, in mm, of each bubble detected and segmented
%    L: labelled image resulting from the image processing algorithm
%    extra_info: structure containing extra information about bubbles
%    (eccentricity, solidity, etc)
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
function [D, L_image, extra_info] = PartialWatershed(img, params)

%Collect parameters from the structure
se = strel('disk', params.Morphological_element_size); %strel object to perform binary operations
nb = params.Connectivity; %neighbourhood used (4 or 8)
marker_size = params.Marker_size; %marker size of the Watershed segmentation, in px
px2mm = params.px2mm; %img resolution
img_resample = params.resample;
bknd_img = params.background_img;
convexity = params.convexity;
eccentricity = params.eccentricity;
solidity = params.solidity;
E_max = params.Max_Eccentricity;
S_min = params.Min_Solidity;
Dmin = params.min_size; %minimum bubble size, in mm!
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

CC = bwconncomp(B);
%Eccentricity: 0 -> circle, 1 -> line; Solidity = Area/ConvexArea
S = regionprops(B,'EquivDiameter','ConvexImage','Perimeter', 'Solidity','Eccentricity','PixelIdxList');

for i = 1:length(S)
    ConvexPerim = regionprops(S(i).ConvexImage, 'Perimeter');
    Convexity(i) = S(i).Perimeter/ConvexPerim.Perimeter;
end 

E = [S.Eccentricity]'; %column vector with eccentricity
C = Convexity'; %column vector with convexity
S = [S.Solidity]';
idx = E>=eccentricity & S<=solidity & C>convexity;
pixels = CC.PixelIdxList(idx);

[r, c] = size(B);
for k=1:length(pixels)
    im = zeros([r, c]);
    B(pixels{k}) = 0;
    im(pixels{k}) = 1;
     R = -bwdist(~im);
     R2 = imhmin(R,marker_size,nb); %J = imhmin(I,H,conn) computes the H-minima transform, where conn specifies the connectivity.
     Ld2 = watershed(R2);
     im(Ld2 == 0) = 0;
     B = imfuse(B,im,'blend'); %Combine image of segmented bubbles and individual bubbles
end
CH = imbinarize(uint16(B));

%remove bubbles touching the borders
CH = imclearborder(CH);


%Now list the detected objects and calculate geometric properties
cc = bwconncomp(CH,4);
%Eccentricity: 0 -> circle, 1 -> line; Solidity = Area/ConvexArea
s = regionprops(cc,'EquivDiameter','Eccentricity','Solidity');

%Reject abnormal objects, possibly unseparated bubbles
e = [s.Eccentricity]'; %column vector with eccentricity
D = [s.EquivDiameter]'; %column vector with diameters
s = [s.Solidity]';
%!!Remember we scaled down the image by some factor!!
D = D * px2mm * 1/img_resample; %now in mm
idx = e>=E_max | s<=S_min | D<Dmin; %abnormal bubbles: too stretched
%remove abnormal bubbles
D = D(~idx);
%collect extra bubble shape descriptors
extra_info.Eccentricity = e(~idx);
extra_info.Solidity = s(~idx);

%Update label image if required. 
if do_batch
    %when doing batch processing we don't need to create a fancy label image 
    L_image = [];
else
    %when processing individual images we can create a nice label image to
    %show the results to the user
    allowableAreaIndexes = ~idx;
    keeperIndexes = find(allowableAreaIndexes);
    keeperBlobsImage = ismember(bwlabel(CH,4), keeperIndexes);
    keeperBlobsImage = imresize(keeperBlobsImage,[n m]); %put it back to original size
    L_image = bwlabel(keeperBlobsImage, nb);

end
