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