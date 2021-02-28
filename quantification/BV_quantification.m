%Default image processing algorithm coming with Bubble Analyser software
%
% Syntax: BV_quantification(I, params)
%
% Inputs:
%    I: image, either rgb or grayscale
%    params: parameters needed for certain operations, either set by the
%    user or in the corresponding .config file
%    
% Outputs:
%    D_32: D_32 of each bubble detected and segmented
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
%    along with Bubble Analyser.  If not, see <https://www.gnu.org/licenses/>.
%
%------------- BEGIN CODE --------------
function [D_32, newLabeledImage] = BV_quantification(img, params)

se = strel('disk', params.Morphological_element_size); %strel object to perform binary operations
nb = params.Neighbourhood_size; %neighbourhood used
px2mm = params.px2mm; %img resolution
img_resample = params.resample;
bknd_img = params.background_img;
E_th = params.Eccentricity;
S_th = params.Solidity;

%use background correction as threshold
if ~isempty(bknd_img)
    if size(bknd_img,3)>1
        bknd_img = rgb2gray(bknd_img);
    end    
    T = adaptthresh(bknd_img, 0.4 , 'ForegroundPolarity', 'dark');
end

if size(img,3)>1
    img = rgb2gray(img);
end
img = imresize(img, img_resample); %resample img to make process faster
if ~isempty(bknd_img)
    BW = imbinarize(img,imresize(T, img_resample));
else
    BW = imbinarize(img);
end
B = imclose(~BW,se);
B = imfill(B,'holes');
B = imclearborder(B); %remove bubbles touching the border
R = -bwdist(~B);

mask = imextendedmin(R,nb);
R2 = imimposemin(R,mask);
Ld2 = watershed(R2);
B(Ld2 == 0) = 0;
CH = bwconvhull(B,'objects');
R3 = -bwdist(~CH);
mask = imextendedmin(R3,nb);
R4 = imimposemin(R3,mask);
Ld3 = watershed(R4,nb);
CH(Ld3==0) = 0;

CC = bwconncomp(CH,4);
S = regionprops(CC,'EquivDiameter','Area','Eccentricity','ConvexImage','Solidity'); %Eccentricity: 0 -> circle, 1 -> line

%reject abnormal bubbles from quantification. check other "region props"
A = [S.Area]'; %column vector with areas
E = [S.Eccentricity]'; %column vector with eccentricity
D = [S.EquivDiameter]'; %column vector with diameters
S = [S.Solidity]';
idx = E>E_th| S<S_th; %abnormal bubbles: too stretch (E>0.85 , check this value!) 1 for water
allowableAreaIndexes = ~idx;
D = D(~idx) * px2mm * 2; %WHY THE *2???
keeperIndexes = find(allowableAreaIndexes);
keeperBlobsImage = ismember(bwlabel(CH), keeperIndexes);
newLabeledImage = label2rgb(bwlabel(keeperBlobsImage, nb));

%Acquisition's D_32
D_32 = sum(D.^3)/sum(D.^2); %in mm