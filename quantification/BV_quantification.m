%Set path to experiment folder
clear all
close all
clc
%%
path = 'G:\My Drive\Imperial College\Experimental Data\Bubble Size Laser System\Second Try - Jan 2020\solids\';
folders = dir(path); %get phases folder names

%For each folder (acquisition) quantify d_32
se = strel('disk',5); %value of pixels used in the close algorithm
for i = 3:length(folders) %first two are '.' and '..'    
    if folders(i).isdir
        acq_folder = folders(i).name;
        display(acq_folder)
        %Calibration info (res and bkg image)
        load([path acq_folder '/calib_info.mat']);
        T = adaptthresh(Background,0.4,'ForegroundPolarity','dark');%use background correction as threshold
        images = dir([path acq_folder '/*.JPG']);
        
        
        %prompt = 'Number of first acquisition? : ';
        %first_img_num = images(j).name;%input(prompt);
        D = [];
        E = [];
        textprogressbar('Processing images ');
        N = length(images);
        for j=3:N
            textprogressbar(j/N*100);
            name_parts = regexpi(images(j).name, '_', 'split');
            img_num = str2double(name_parts{2}(1:end-4));
            I = imread([path acq_folder '/' images(j).name]);
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
            mask = imextendedmin(R,8);
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
            %fig1=figure('Color',[1 1 1]);
            %imshowpair(I,newLabeledImage,'montage')
            D_aux = D_aux(~idx)*px2mm*2; %record only normal bubbles
            D = [D; D_aux]; %#ok
            E_aux = E_aux(~idx);
            E = [E; E_aux]; %#ok
            
        end
        textprogressbar(' done');
        %Acquisition's D_32
        D_32 = sum(D.^3)/sum(D.^2); %in mm
        u = round(D_32)+2;
        %Acqusition's histograma EquivDiameter    
        bubbles_psd(D,100,[0 u],'Eq. diameter [mm]'); %100 classes, show only between 0 and round(D_32)+2
        title([acq_folder ' d_{32}=' num2str(D_32,'%1.2f')]);
        export_fig([path acq_folder '_histogram.pdf'])
        close 

        save([path acq_folder '/quantification.mat'],'D','D_32','E');
    end
end

