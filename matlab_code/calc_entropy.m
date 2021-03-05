load('final.mat', 'final');

%% getting entropy for each image
mat = final; % just because I don't like the name of var
numImgs = size(mat,2);

complexity = zeros(numImgs,1);
labels = zeros(numImgs,1);

for i = 1:numImgs
    this_img_name = ['../../stimuli/', mat(i).imageName, '.png'];
    img = imread(this_img_name);
    
    complexity(i) = entropy(img);
    
    % nq label
    if mat(i).nq > 0
        noise_label = 1; % 1 == hot
    elseif mat(i).nq <= 0
        noise_label = 2; % 2 == cold
    end
    
    labels(i) = noise_label;
end
%% compare noisy and quiet images
noisy_imgs_idx = find(labels==1);
quiet_imgs_idx = find(labels==2);

[h, pval, CI, stats] = ttest(complexity(noisy_imgs_idx), complexity(quiet_imgs_idx ));

complexity_imgs = [complexity(noisy_imgs_idx), complexity(quiet_imgs_idx )];

bar(1:2, mean(complexity_imgs,1));