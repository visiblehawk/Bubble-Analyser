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
path = 'G:\My Drive\Imperial College\Experimental Data\Bubble Size Laser System\Second Try - Jan 2020\solids\';
folders = dir(path); %get folder names
%For each folder (acquisition) calibrate resolution and background
%illumination
for i = 3:length(folders) %first two are '.' and '..'   
    if folders(i).isdir
        acq_folder = folders(i).name;
        display(acq_folder)
        images = dir([path acq_folder '/*.JPG']);
        %% get background image
        %         prompt = 'Image number for backgound correction? : ';
        %         bkg_img_num = input(prompt);    
        %         images = dir([path acq_folder '/*.JPG']);
        %         for j=1:length(images)    
        %             name_parts = regexpi(images(j).name, '_', 'split');
        %             img_num = str2double(name_parts{2}(1:end-4));
        %             if img_num==bkg_img_num
        %                 I = imread([path acq_folder '/' images(j).name]);
        %                 Background = rgb2gray(I);
        %                 break
        %             end
        %         end
        I = imread([path acq_folder '/' images(1).name]);
        Background = rgb2gray(I);

        %% Get resolution
        %         prompt = 'Image number for magnification calibration? : ';
        %         mag_img_num = input(prompt);        
        %         for j=1:length(images)    
        %             name_parts = regexpi(images(j).name, '_', 'split');
        %             img_num = str2double(name_parts{2}(1:end-4));
        %             if img_num==mag_img_num
        %                 I = imread([path acq_folder '/' images(j).name]);
        %                 I = rgb2gray(I);
        %                 figure, pause(1)
        %                 [x,y,~] = impixel(I); %Get two points separated by 1cm
        %                 d = sqrt(diff(x)^2 + diff(y)^2);
        %                 px2mm = 10/d;
        %                 break
        %             end
        %         end
        I = imread([path acq_folder '/' images(2).name]);
        I = rgb2gray(I);
        figure, pause(1)
        [x,y,~] = impixel(I); %Get two points separated by 1cm
        d = sqrt(diff(x)^2 + diff(y)^2);
        px2mm = 10/d;

        close all
        save([path acq_folder '/calib_info.mat'],'px2mm','Background');
    end
end
display('end');