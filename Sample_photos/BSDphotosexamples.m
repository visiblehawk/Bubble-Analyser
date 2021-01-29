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
%Set path to experiment folder
% Examples with image
clear all
close all
clc
%%
path = 'G:\My Drive\Imperial College\Experimental Data\Impeller Design Tests\BV Photos\OK Stator\2 phases\MIBC\Full Factorial\Test 1\2 MIBC 20 PPM\3 MIBC 20 PPM (-1,1)\';

%For each folder (acquisition) quantify d_32
se = strel('disk',5); %value of pixels used in the close algorithm ARBITRARY

%Calibration info (res and bkg image)
load([path '/calib_info.mat']);
T = adaptthresh(Background,0.4,'ForegroundPolarity','dark');%use background correction as threshold
images = dir([path '/*.JPG']);
     
%prompt = 'Number of first acquisition? : ';
%first_img_num = images(j).name;%input(prompt);
D = [];
E = [];
j=22; %number of photo (between 3 an 303)
name_parts = regexpi(images(j).name, '_', 'split');
img_num = str2double(name_parts{2}(1:end-4));
I = imread([path '/' images(j).name]);
I = rgb2gray(I);
I = I(1:2:end,1:2:end); %makes image half size
BW = imbinarize(I,T(1:2:end,1:2:end)); 
B = imclose(~BW,se);
B = imfill(B,'holes');
B = imclearborder(B);
R = -bwdist(~B);
%Ld = watershed(R);
%bw2 = B;
%bw2(Ld == 0) = 0;
mask = imextendedmin(R,8); %8 is magic number
R2 = imimposemin(R,mask);
Ld2 = watershed(R2);
B(Ld2 == 0) = 0;
CH = bwconvhull(B,'objects');
R3=-bwdist(~CH);
mask = imextendedmin(R,8);
mask2 = imextendedmin(R3,8);
R4 = imimposemin(R3,mask2);
Ld3=watershed(R4);
CH(Ld3==0)=0;
CC = bwconncomp(CH,4); %TODO do some object separation, check "Watershed transform"
L = label2rgb(labelmatrix(CC));
S = regionprops(CC,'EquivDiameter','Area','Eccentricity','ConvexImage','Solidity'); %Eccentricity: 0 -> circle, 1 -> line
%TODO reject abnormal bubbles from quantification. check other "region props"
A = [S.Area]'; %column vector with areas
E_aux = [S.Eccentricity]'; %column vector with eccentricity
D_aux = [S.EquivDiameter]'; %column vector with diameters 
S_aux= [S.Solidity]';
idx = E_aux>0.85| S_aux<0.9; %abnormal bubbles: too stretch (E>0.85 , check this value!) 1 for water
allowableAreaIndexes = ~idx;
keeperIndexes = find(allowableAreaIndexes); 
keeperBlobsImage = ismember(bwlabel(CH), keeperIndexes);
newLabeledImage = label2rgb(bwlabel(keeperBlobsImage, 8));  
fig1=figure('Color',[1 1 1]);
ax1 = axes('Parent',fig1);
box(ax1,'on')
hold(ax1,'on')
imshowpair(I,newLabeledImage,'montage')
D_aux = D_aux(~idx)*px2mm*2; %record only normal bubbles
D = [D; D_aux]; %#ok
E_aux = E_aux(~idx);
E = [E; E_aux]; %#ok
