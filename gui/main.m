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
% email: f.reyes@uq.edu.au,  p.quintanilla18@imperial.ac.uk
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

%% Load files in folder
%check if path has a final slash ##TODO. check if it works on linux
if(path_to_folder(end)~='/')
    path_to_folder = [path_to_folder '/']; %add it if not
end
%Load file names in folder
folder_files = dir(path_to_folder); 
folder_files = folder_files(~[folder_files.isdir]); %exclude folders

%% Separate image files from whatever else it might be there in the folder
%figure out the extension if the image files (.jpeg, tiff, png, etc...)
[~, ~, fextensions] = cellfun(@fileparts, {folder_files.name}, 'UniformOutput', false);
[s, ~, j]=unique(fextensions);
img_extension = s{mode(j)};
%with the extension we can now get the image file list
img_files = dir([path_to_folder '*' img_extension]);
clear s j folder_files fextensions %remove unused variables

%% Load sample image and calibration images
%The code uses two calibration images, one is for doing background
%correction if lighting is uneven throughout the field of view. The second
%one is for calibrating the resolution, i.e how many pixels per mm. We also
%show a random image to show the processing results before running the
%batch quantification, similar to a sandbox test.

%create figures to show claibration and sample images
%calibration, a subplot to show both
figure('Name', 'Calibration')
calib_ax1 = subplot(1, 2, 1);
calib_ax2 = subplot(1 ,2 , 2);
%Sample image
figure('Name', 'Sample Image')
sample_ax = axes('parent', gcf);

%By default we asume the first image is the background image and the second
%one is the calibration image. 
%TODO. let the user can later adjust this using the GUI
[bkgnd_img, img_map] = imread([path_to_folder img_files(1).name]);
imshow(bkgnd_img, img_map, 'Parent', calib_ax1)
calib_img = imread([path_to_folder img_files(2).name]);
imshow(calib_img, img_map, 'Parent', calib_ax2)

rnd_idx = 2 + randi(length(img_files)-2);
sample_img = imread([path_to_folder img_files(rnd_idx).name]);
imshow(sample_img, img_map, 'Parent', sample_ax)
clear rnd_idx 

%% Calibrate
%transform into grayscale
bkgnd_img = rgb2gray(bkgnd_img); 
calib_img = rgb2gray(calib_img);

%Resolution gets calibrated by the user, clicking in two points separated by 1 cm
axes(calib_ax2) %pick the apropiate axes
[x, y, ~] = impixel(calib_img); %Get two points separated by 1cm
d = sqrt(diff(x)^2 + diff(y)^2);
px2mm = 10/d; %resolution stored as number of pixels in 10mm

%Store the results in a mat file and save the images used
calib_path = './calibration/';
if ~exist(calib_path, 'dir')
    mkdir(calib_path)
end
imwrite(bkgnd_img, [calib_path 'background_img.tiff'], 'Compression', 'none');
imwrite(calib_img, [calib_path 'calibration_img.tiff'], 'Compression', 'none');
save([calib_path 'calib_info.mat'],'px2mm','bkgnd_img');
clear d x y

%% Process sample image
%use a random image as a sandbox to run the algorithms before doing a batch
%processing
params.se = strel('disk', 5); %value of pixels used in the close algorithm
params.nb = 8; %neighbourhood used
params.px2mm = px2mm; %img resolution
params.resample = 0.5;
params.background_img = bkgnd_img;

[D32, label_img, sample_img] = BV_quantification(sample_img,params);
axes(sample_ax) %pick the apropiate axes
imshow(label_img)

%Store the params and results 
label_path = './working_files/labelling/';
if ~exist(label_path, 'dir')
    mkdir(label_path)
end
imwrite(sample_img, [label_path 'sample_img.tiff'], 'Compression', 'none');
imwrite(label_img, [label_path 'label_img.tiff'], 'Compression', 'none');
save([label_path 'process_params.mat'],'params','bkgnd_img');

%------------- END OF CODE --------------