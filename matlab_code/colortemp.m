function [temp, val_red, val_green, val_blue] = colortemp(img)

img = im2double(img);
himg = rgb2hsv(img);
himg(:,:,2:3) = 1;
img2 = hsv2rgb(himg);
avg_col = squeeze(mean(mean(img2,1),2));

% scalar products with pure red and blue
val_red = avg_col' * [1,0,0]';
val_green = avg_col' * [0,1,0]';
val_blue = avg_col' * [0,0,1]';

temp = (val_red - val_blue) / (val_red + val_blue);

