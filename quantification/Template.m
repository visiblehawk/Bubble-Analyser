%Template image processing algorithm coming with Bubble Analyser software
%
% Syntax: Template(I, params)
%
% Inputs:
%    I: image, either rgb or grayscale
%    params: parameters needed for certain operations, either set by the
%    user or in the corresponding .config file
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
function [D_32, newLabeledImage] = Template(img, params)
angle = params.angle;
scale = params.scale;
newLabeledImage = imrotate( imresize(img,scale),angle);
D_32 = -1;
img = [];