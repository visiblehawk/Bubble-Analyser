%Template image processing algorithm coming with Bubble Analyser software
%
% Syntax: FindCircles(I, params)
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
function [D, L_image, extra_info] = FindCircles(img, params)

%Collect parameters from the structure
se = strel('disk', params.Morphological_element_size); %strel object to perform binary operations;
nb = params.Connectivity; %neighbourhood used (4 or 8)
marker_size = params.Marker_size; %marker size of the Watershed segmentation, in px
Smin = params.SmallBubbles_minsize;
Smax = params.SmallBubbles_maxsize;
Bmin = params.BigBubbles_minsize;
Bmax = params.BigBubbles_maxsize;
smallSensitivity = params.SmallBubbleSensitivity;
smallEdgethreshold = params.SmallBubbleEdgethreshold;
bigSensitivity = params.BigBubbleSensitivity;
bigEdgethreshold = params.BigBubbleEdgethreshold;
px2mm = params.px2mm; %img resolution
img_resample = params.resample;
bknd_img = params.background_img;
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

%remove bubbles touching the borders
B = imclearborder(B);

%Now use watershed to separate bubbles that are overlapping
R = -bwdist(~B);
% mask = imextendedmin(R,nb);
% R2 = imimposemin(R,mask);
R2 = imhmin(R,marker_size,nb); %J = imhmin(I,H,conn) computes the H-minima transform, where conn specifies the connectivity.
Ld2 = watershed(R2);
B(Ld2 == 0) = 0;
CH = bwconvhull(B,'objects');
R3 = -bwdist(~CH);
mask = imextendedmin(R3,nb);
R4 = imimposemin(R3,mask);
Ld3 = watershed(R4,nb);
CH(Ld3==0) = 0;

img = CH;
% Find circles and locate them by centers and radii.
[centers_1, radii_1, ~] = imfindcircles(img, ...
        [Smin, Smax], ...                                              % Radius range in pixels.
        'ObjectPolarity', 'bright', ...                            % Find circular objects that are darker than the background, [brighter, darker].
        'method', 'twostage', ...                                % Two methods for finding circles, [phase coding, twostage].
        'sensitivity', smallSensitivity, ...                          % 'Sensitivity', [0,1], is set to 0.85 by default.
       'edgethreshold', smallEdgethreshold);     					 % A high value (closer to 1) will allow only the strong edges to be included, whereas a low value (closer to 0) includes even the weaker edges.
                                

[centers_2, radii_2, ~] = imfindcircles(img, ...
        [Bmin, Bmax], ...
        'ObjectPolarity', 'bright', ...
        'Method','TwoStage',...
        'sensitivity', bigSensitivity, ...
        'edgethreshold', bigEdgethreshold);


centers = [centers_1; centers_2];
radii = [radii_1; radii_2];
D = 2*[radii_1; radii_2]; %column vector with diameters


D = D * px2mm * 1/img_resample; %now in mm

%remove abnormal bubbles
idx = D < Dmin;
D = D(~idx);
centers = centers(~idx,:);
radii = radii(~idx);

extra_info = []; %nothing to include for now

if do_batch
    % when doing batch processing we don't need to create a fancy label image
    L_image = [];
else
    %when processing individual images we can create a nice image showing
    %the found circles

    % start with an empty label img
    L_image = zeros(size(img));
    
    %for each circle, make pixels red
    theta = 0:pi/50:2*pi;
    for circ = 1:length(D)
        xp = centers(circ,2) + radii(circ)*cos(theta);
        yp = centers(circ,1) + radii(circ)*sin(theta);
        idx = xp<1; xp(idx) = []; yp(idx) = [];
        idx = xp>n; xp(idx) = []; yp(idx) = [];
        idx = yp<1; xp(idx) = []; yp(idx) = [];
        idx = yp>m; xp(idx) = []; yp(idx) = [];
        L_image(round(xp), round(yp)) = circ; %idx of the circle
    end   
    L_image = imresize(uint16(L_image), [n,m]);
end


