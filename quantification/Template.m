function [D_32, newLabeledImage, img] = Template(img, params)
angle = params.angle;
scale = params.scale;
newLabeledImage = imrotate( imresize(img,scale),angle);
D_32 = -1;
img = [];