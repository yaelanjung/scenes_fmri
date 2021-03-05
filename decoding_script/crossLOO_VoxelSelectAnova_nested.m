function [predictLabels, decisionValues, usedVoxels, trainingFVals, nVoxels, trainingAccuracy] = crossLOO_VoxelSelectAnova_nested(trainSamples,testSamples,trainLabels,blockLength,param_string, numVoxelRange)

[nTrainIdx, thisVoxelSize] = size(trainSamples);
nTrain = nTrainIdx/blockLength;
nestTrainIdx = sort(repmat([1:nTrain],1,blockLength));
usedVoxelMat = cell(length(numVoxelRange),1);
fValsMat = cell(length(numVoxelRange),1);
acc = zeros(length(numVoxelRange),1);

% voxel selection
for i = 1:thisVoxelSize
    [~, tab, ~] = anova1(trainSamples(:,i), trainLabels, 'off');
    fVal(i) = tab{2,5};
end
[fValues, index] = sortrows(fVal', -1);

% cross validation
for v = 1:length(numVoxelRange)
    numV = numVoxelRange(v);
    if thisVoxelSize <= numV
        usedVoxels = index;
        fVals = fValues;
    else
        usedVoxels = index(1:numV);
        fVals = fValues(1:numV);
    end

    usedVoxelMat{v} = usedVoxels;
    fValsMat{v} = fVals;
    thisSamples = trainSamples(:, usedVoxels);
    
    nestedPredictLabels = zeros(nTrainIdx,1);
    nestedDecisionValues = zeros(nTrainIdx,1);
    
    % Do crossValidate here
    for t = 1:nTrain
%         fprintf('\t VoxelSelection: LOO cross validation fold %d of %d.\n',t,nTrain);
        testIdx = find(nestTrainIdx ==t);
        trainIdx = setdiff([1:nTrainIdx],testIdx);

        model = svmlearn_oaa_multiclass(thisSamples(trainIdx',:),trainLabels(trainIdx),param_string);
        [nestedPredictLabels(testIdx),nestedDecisionValues(testIdx)] = svmclassify_oaa_multiclass(thisSamples(testIdx,:), model);
    end
    
    % get accuracy for this size of voxels
    acc(v) = makeConfMatrix(trainLabels,nestedPredictLabels);
    clear usedVoxels fVals thisSamples;
end

% who did the best?
maxIdx = find(acc==max(acc));
if length(maxIdx) > 1
    maxIdx = min(maxIdx);
end

nVoxels = numVoxelRange(maxIdx);
usedVoxels = usedVoxelMat{maxIdx};
trainingFVals = fValsMat{maxIdx};
trainingAccuracy = acc(maxIdx);

% classification
model = svmlearn_oaa_multiclass(trainSamples(:,usedVoxels),trainLabels,param_string);
[predictLabels,decisionValues] = svmclassify_oaa_multiclass(testSamples(:,usedVoxels), model);