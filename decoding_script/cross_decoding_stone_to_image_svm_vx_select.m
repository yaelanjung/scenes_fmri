% cross-decoding stone to image
% using svm classifier
% in individual ROIs

clc;
currDir = pwd;
% training
training_runs = {'temp_r1', 'temp_r2', 'temp_r3', 'temp_r4'};
% testing
test_runs={'HC1', 'HC2'};

numTrainingRuns = length(training_runs);
numTestRuns = length(test_runs);

% call function to load ROI names
list_of_rois;
masks = ROIs;

% set result directory
input_path='/bwlab/fMRI/scenesTS/';
output_path='/bwlab/fMRI/scenesTS/%s/matlab_code/';

% coefficient index for each label
label_hot = 2;
label_cold = 4;
cat_labels = [label_hot, label_cold];
numCats =2;

numMasks = length(masks);
numSubj = 20;

svmParams = '-t 0 -c 0.05 -v 0';

% for voxel selection
numVoxelRange = .1:.05:1; % percentage for voxel selection
savename = 'cross-decoding_stone_to_image_corr_vx_select_hc_runs.mat';
%%
acc = nan(numSubj,numMasks);

for s = 1:numSubj
    subj = sprintf('sub-1%.2d', s);
    
    % path information
    img_data_path=fullfile(input_path,subj,'/ses-main/regressions'); % data from subject
    stone_data_path=fullfile(input_path,subj,'/ses-loc/regress_temp'); % data from subject
    mask_path=fullfile(input_path,subj, 'ses-loc/masks'); % whole brain mask
    fprintf('::: decoding temp from stone to image in %s :::\n', subj);
    
    % loop over each ROI
    for m = 1:numMasks
        roiMask = masks{m};
        mask_fn = sprintf([mask_path, '/%s_%s+orig'], subj, roiMask);
        if exist([mask_fn '.HEAD'], 'file')
            ds_mask = cosmo_fmri_dataset(mask_fn, 'mask', mask_fn);
            img_samples = nan(numCats*numTestRuns,size(ds_mask.samples,2));
            stone_samples = nan(numCats*numTrainingRuns,size(ds_mask.samples,2));
            stone_targets = [];
            stone_chunks = [];
            img_targets = [];
            img_chunks = [];
            
            % load the training run data
            for runIdx = 1:numTrainingRuns
                brikName = [stone_data_path, '/', subj, '_', training_runs{runIdx},'_sm2_bucket+orig'];
                ds=cosmo_fmri_dataset(brikName,'mask',mask_fn);
                stone_samples((runIdx-1)*numCats+1:runIdx*numCats,:) = ds.samples([cat_labels(:)],:);
                stone_targets = [stone_targets, 1:numCats];
                stone_chunks = [stone_chunks, ones(1,numCats)*runIdx];
                
            end
            
            % load the test run data
            for runIdx = 1:numTestRuns
                brikName = [img_data_path, '/', subj, '_', test_runs{runIdx},'_HC_sm2_bucket+orig'];
                ds=cosmo_fmri_dataset(brikName,'mask',mask_fn);
                img_samples((runIdx-1)*numCats+1:runIdx*numCats,:) = ds.samples([cat_labels(:)],:);
                img_targets = [img_targets, 1:numCats];
                img_chunks = [img_chunks, (ones(1,numCats)*runIdx)+numTrainingRuns];

            end
            
            trainSamples = stone_samples;
            trainLabels = stone_targets';
            
            testSamples = img_samples;
            testLabels = img_targets';
            
            % perform decoding
            [predictLabels, decisionValues, usedVoxels, usedFStat, selectedNVoxel] = crossLOO_VoxelSelectAnova_nested(trainSamples,testSamples,trainLabels,blockLength*numCats,svmParams,numVoxelRange);
            trueLabels = testLabels;
            
            [CRs(s,m),CMs{s,m}] = makeConfMatrix(trueLabels,predictLabels);
            fprintf('decoding accuracy in %s in %s = %f\n',roiMask, subj,CRs(s,m));
            voxelIdx{s,m} = usedVoxels;
            fValMat{s,m} = usedFStat;
            nVoxelMat{s,m} = selectedNVoxel;

            workDir = pwd;
            cd(currDir);
            save(savename,'CRs','CMs' ,'masks', 'nVoxelMat', 'voxelIdx', 'fValMat');
            cd(workDir); 
        end
    end
end