function [val_l, val_a, val_b] = colortemp_lab(img)

img = im2double(img);
himg = rgb2hsv(img);
himg(:,:,2:3) = 1;
img_rgb = hsv2rgb(himg);
img_lab = rgb2lab(img_rgb);
avg_col = squeeze(mean(mean(img_lab,1),2));

% scalar products with pure red and blue
val_l = avg_col' * [1,0,0]';
val_a = avg_col' * [0,1,0]';
val_b = avg_col' * [0,0,1]';

