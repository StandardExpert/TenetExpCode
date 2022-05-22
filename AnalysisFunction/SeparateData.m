function [forwardData,backwardData] = SeparateData(totalAnswerArray,judgmentColumn)
forwardDataMarker = [];
backwardDataMarker = [];
for ii = 1:size(totalAnswerArray,1)
    if totalAnswerArray{ii,judgmentColumn} == 1
        forwardDataMarker = [forwardDataMarker,ii];
    elseif totalAnswerArray{ii,judgmentColumn} == 2
        backwardDataMarker = [backwardDataMarker,ii];
    end
end
forwardData = totalAnswerArray(forwardDataMarker,:);
backwardData = totalAnswerArray(backwardDataMarker,:);
end