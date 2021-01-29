% function main(path_to_folder)
%main.m - Bubble sizer image processing code, soon to be the GUI
%This script calls all other functions/subrutines.
%At some point we need to change this into a GUI asociated M-file
%
% Syntax:  main(path_to_folder)
%
% Inputs:
%    path_to_folder - path to the folder with the images to be analysed
%    
% Outputs:
%    none
%
% Example: 
%    main('./Sample_photos/')
%
% Author: Reyes, Francisco; Quintanilla, Paulina; Mesa, Diego
% email: f.reyes@uq.edu.au,  
% Website: https://gitlab.com/frreyes1/bubble-sizer
% Copyright Oct-2020;
%
%This file is part of Foobar.
%
%    Foobar is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation version 3 only of the License.
%
%    Foobar is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
%
%------------- BEGIN CODE --------------
function [D_32, newLabeledImage, img] = BV_quantification(img, params)

se = params.se; %strel object to perform binary operations
nb = params.nb; %neighbourhood used
px2mm = params.px2mm; %img resolution
img_resample = params.resample;
bknd_img = params.background_img;

%use background correction as threshold
T = adaptthresh(bknd_img, 0.4 , 'ForegroundPolarity', 'dark');

if size(img,3)>1
    img = rgb2gray(img);
end
img = imresize(img, img_resample); %resample img to make process faster
BW = imbinarize(img,imresize(T, img_resample));
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
Ld3 = watershed(R4);
CH(Ld3==0) = 0;

if nb>4
    nb = 4;
end

CC = bwconncomp(CH,nb);
S = regionprops(CC,'EquivDiameter','Area','Eccentricity','ConvexImage','Solidity'); %Eccentricity: 0 -> circle, 1 -> line

%reject abnormal bubbles from quantification. check other "region props"
A = [S.Area]'; %column vector with areas
E = [S.Eccentricity]'; %column vector with eccentricity
D = [S.EquivDiameter]'; %column vector with diameters
S = [S.Solidity]';
idx = E>0.85| S<0.9; %abnormal bubbles: too stretch (E>0.85 , check this value!) 1 for water
allowableAreaIndexes = ~idx;
D = D(~idx) * px2mm * 2; %WHY THE *2???
keeperIndexes = find(allowableAreaIndexes);
keeperBlobsImage = ismember(bwlabel(CH), keeperIndexes);
newLabeledImage = label2rgb(bwlabel(keeperBlobsImage, nb));

%Acquisition's D_32
D_32 = sum(D.^3)/sum(D.^2); %in mm