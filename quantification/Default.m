%Default image processing algorithm coming with Bubble Analyser software
%
% Syntax: Default(I, params)
%
% Inputs:
%    img: image, either rgb or grayscale
%    params: parameters needed for certain operations, default values set by the
%    corresponding .config file, but can be edited by the user
%
% Outputs:
%    D: number array with the equivalent diameter, in mm, of each bubble detected and segmented
%    L: labelled image resulting from the image processing algorithm
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
function [D, L_image] = Default(img, params)

%Collect parameters from the structure
se = strel('disk', params.Morphological_element_size); %strel object to perform binary operations
nb = params.Connectivity; %neighbourhood used (4 or 8)
marker_size = params.Marker_size; %marker size of the Watershed segmentation, in px
px2mm = params.px2mm; %img resolution
img_resample = params.resample;
bknd_img = params.background_img;
E_max = params.Max_Eccentricity;
S_min = params.Min_Solidity;
Dmin = params.min_size; %minimum bubble size, in mm!

%Resize images for making processing faster
img = imresize(img, img_resample); %resample img to make process faster
if size(img,3)>1
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

%remove bubbles touching the borders
B = imclearborder(B);

%Now use watershed to separate bubbles that are overlapping
R = -bwdist(~B);
% mask = imextendedmin(R,nb);
% R2 = imimposemin(R,mask);
R2 = imhmin(R,marker_size,nb);
Ld2 = watershed(R2);
B(Ld2 == 0) = 0;
CH = bwconvhull(B,'objects');
R3 = -bwdist(~CH);
mask = imextendedmin(R3,nb);
R4 = imimposemin(R3,mask);
Ld3 = watershed(R4,nb);
CH(Ld3==0) = 0;

%Now list the detected objects and calculate geometric properties
CC = bwconncomp(CH,4);
%Eccentricity: 0 -> circle, 1 -> line; Solidity = Area/ConvexArea
S = regionprops(CC,'EquivDiameter','Eccentricity','Solidity');

%Reject abnormal objects, possibly unseparated bubbles
E = [S.Eccentricity]'; %column vector with eccentricity
D = [S.EquivDiameter]'; %column vector with diameters
S = [S.Solidity]';
%!!Remember we scaled down the image by some factor!!
D = D * px2mm * 1/img_resample; %now in mm
idx = E>=E_max | S<=S_min | D<Dmin; %abnormal bubbles: too stretched


outputImageStyle = 'mixed'; % 'default','mixed','outline'
%Update label image
allowableAreaIndexes = ~idx;
keeperIndexes = find(allowableAreaIndexes);
keeperBlobsImage = ismember(bwlabel(CH), keeperIndexes);
L_image = label2rgb(bwlabel(keeperBlobsImage, nb));

switch(outputImageStyle)
    case 'default'
    case 'mixed'
        % Gordon - Showing original image with bubble labels
        L_image=im2double(L_image);
        bwImage = im2double(img);
        L_image = L_image .* cat(3, bwImage, bwImage, bwImage);
    case 'outline'
         L_image=im2double(img);
         B = bwboundaries( keeperBlobsImage,'noholes' );
         
         figure(1)
         hold off
         imshow(L_image)
         hold on
         for k = 1:length(B)
             boundary = B{k};
             plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 2)
         end
         
         % Not integrated with App currently so return 'default'
         L_image = label2rgb(bwlabel(keeperBlobsImage, nb));
end


%Return D
D = D(~idx); %remove abnormal bubbles
