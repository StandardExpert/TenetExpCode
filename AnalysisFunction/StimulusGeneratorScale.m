function StimulusGeneratorScale(participantNumber,trainNumber,testNumber,itemNumber,sequenceLength)
% 数据格式：trialID, trialType, trialMatrix, direction, probRorW, probeMatrix, answer, RT

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
probRorW = [1 2 2 1 2];
for ii = 1:trainNumber
    lineIndex = ii;
    stimulusCell{lineIndex,1} = ii;
    stimulusCell{lineIndex,2} = 'train';
    randSequence = randperm(itemNumber);
    stimulusCell{lineIndex,3} = randSequence(1:sequenceLength);
    stimulusCell{lineIndex,4} = sequenceDirection(ii);
    stimulusCell{lineIndex,5} = probRorW(ii);
    if probRorW(ii) == 1
        %如果正确答案为“相同”，则探针就是原来的序列（或逆序）
        if stimulusCell{lineIndex,4} == 1
            probeMatrix = stimulusCell{lineIndex,3};
        else
             probeMatrix = stimulusCell{lineIndex,3}(sequenceLength:-1:1);
        end
    else
        %如果答案为不同，则探针就是另外一个随机序列
        while 1
            randSequence = randperm(itemNumber);
            probeMatrix = randSequence(1:sequenceLength);
            if probeMatrix ~= stimulusCell{lineIndex,3}
                break;
            end
        end
    end
    stimulusCell{lineIndex,6} = probeMatrix;
end

%----------test
%1顺序，2逆序
sequenceDirection = [ones(testNumber/2,1) ones(testNumber/2,1)*2];
sequenceDirectionIndex = randperm(testNumber);
probRorW = [ones(testNumber/2,1) ones(testNumber/2,1)*2];
probRorWIndex = randperm(testNumber);
for ii = 1:testNumber
    lineIndex = ii + trainNumber;
    stimulusCell{lineIndex,1} = ii;
    stimulusCell{lineIndex,2} = 'test';
    randSequence = randperm(itemNumber);
    stimulusCell{lineIndex,3} = randSequence(1:sequenceLength);
    stimulusCell{lineIndex,4} = sequenceDirection(sequenceDirectionIndex(ii));
    stimulusCell{lineIndex,5} = probRorW(probRorWIndex(ii));
    if probRorW(ii) == 1
        %如果正确答案为“相同”，则探针就是原来的序列（或逆序）
        if stimulusCell{lineIndex,4} == 1
            probeMatrix = stimulusCell{lineIndex,3};
        else
             probeMatrix = stimulusCell{lineIndex,3}(sequenceLength:-1:1);
        end
    else
        %如果答案为不同，则探针就是另外一个随机序列
        while 1
            randSequence = randperm(itemNumber);
            probeMatrix = randSequence(1:sequenceLength);
            if probeMatrix ~= stimulusCell{lineIndex,3}
                break;
            end
        end
    end
    stimulusCell{lineIndex,6} = probeMatrix;
end

%--------------------------------------------------------------------------
%                                2.Save
%--------------------------------------------------------------------------
save([participantNumber 'StimulusScale.mat'],'stimulusCell');

end