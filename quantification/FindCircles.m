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
sensitivity = params.sensitivity;
edgethreshold = params.edgethreshold;
px2mm = params.px2mm; %img resolution
img_resample = params.resample;
bknd_img = params.background_img;
%E_max = params.Max_Eccentricity;
%S_min = params.Min_Solidity;
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

% Find circles and locate them by centers and radii.
[centers_1, radii_1, metric_1] = imfindcircles(BW, ...
        [5,30], ...                                              % Radius range in pixels.
        'ObjectPolarity', 'dark', ...                            % Find circular objects that are darker than the background, [brighter, darker].
        'method', 'twostage', ...                                % Two methods for finding circles, [phase coding, twostage].
        'sensitivity', sensitivity, ...                                  % 'Sensitivity', [0,1], is set to 0.85 by default.
       'edgethreshold', edgethreshold)     																															 % A high value (closer to 1) will allow only the strong edges to be included, whereas a low value (closer to 0) includes even the weaker edges.
                                

[centers_2, radii_2, metric_2] = imfindcircles(BW, ...
        [30,900], ...
        'ObjectPolarity', 'dark', ...
        'Method','TwoStage',...
        'sensitivity', sensitivity, ...
        'edgethreshold', edgethreshold)
        
%Now list the detected objects and calculate geometric properties

%Eccentricity: 0 -> circle, 1 -> line; Solidity = Area/ConvexArea
S = regionprops(B,'Eccentricity','Solidity');

E = [S.Eccentricity]'; %column vector with eccentricity
S = [S.Solidity]';

centers = [centers_1; centers_2];
D = [radii_1, radii_2]; %column vector with diameters
D = D * px2mm * 1/img_resample; %now in mm
idx =  D < Dmin;

%remove abnormal bubbles
D = D(~idx);
centers = centers(~idx);

%collect extra bubble shape descriptors
extra_info.Eccentricity = E(~idx);
extra_info.Solidity = S(~idx);

% Create the labeled circles
Label = []
for i = 1:length(D)
    k = 1;
    for theta = 0:1:360
       Label(k,2) = centers(i,2) + D(i)*cosd(theta);
       Label(k,1) = centers(i,1) + D(i)*sind(theta);
       k = k+1;
    end
end

% Save the label circles to L_image
L_image = zeros(size(img));
for i = 1:length(Label)
    L_image(uint(Label(i,1)),uint(Label(i,2))) = 1;
end

if do_batch
    % when doing batch processing we don't need to create a fancy label image
    L_image = [];
else
    %when processing individual images we can create a nice label image to
    %show the results to the user
    L_image = imresize(L_image, [n,m]);

end


