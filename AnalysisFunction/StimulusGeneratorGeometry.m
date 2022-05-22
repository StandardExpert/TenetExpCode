function StimulusGeneratorGeometry(participantNumber,trainNumber,testNumber,itemNumber,sequenceLength)
% 数据格式：trialID, trialType, trialMatrix, direction, answer, RT

%--------------------------------------------------------------------------
%                      0. Rearrange the enviorment
%--------------------------------------------------------------------------
% trainNumber = 5;
% testNumber = 40;
% itemNumber = 7;
% sequenceLength = 5;
% participantNumber = '201811061199';

stimulusCell = cell( (trainNumber + testNumber), 3 );

%--------------------------------------------------------------------------
%                         1. Generate Matrix
%--------------------------------------------------------------------------
%----------train
%1顺序，2逆序
sequenceDirection = [1 1 2 2 1];
for ii = 1:trainNumber
    lineIndex = ii;
    stimulusCell{lineIndex,1} = ii;
    stimulusCell{lineIndex,2} = 'train';
    randSequence = randperm(itemNumber);
    stimulusCell{lineIndex,3} = randSequence(1:sequenceLength);
    stimulusCell{lineIndex,4} = sequenceDirection(ii);
end

%----------test
%1顺序，2逆序
sequenceDirection = [ones(testNumber/2,1) ones(testNumber/2,1)*2];
sequenceDirectionIndex = randperm(testNumber);
for ii = 1:testNumber
    lineIndex = ii + trainNumber;
    stimulusCell{lineIndex,1} = ii;
    stimulusCell{lineIndex,2} = 'test';
    randSequence = randperm(itemNumber);
    stimulusCell{lineIndex,3} = randSequence(1:sequenceLength);
    stimulusCell{lineIndex,4} = sequenceDirection(sequenceDirectionIndex(ii));
end

%--------------------------------------------------------------------------
%                                2.Save
%--------------------------------------------------------------------------
save([participantNumber 'StimulusGeometry.mat'],'stimulusCell');

end