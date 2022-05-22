function [totalRrightOrWrong,allRightOrWrong] = JudgeRightOrWrong(allStimArray,allTargetType,allReactionArray)
%先把该反转的答案翻转过来
for ii = 1:length(allTargetType)
    if allTargetType(ii) == 2
        allStimArray(ii,:) = allStimArray(ii,end:-1:1);
    end
end
allRightOrWrong = (allStimArray == allReactionArray);

totalRrightOrWrong = zeros(size(allRightOrWrong,1),1);
for ii = 1:length(allRightOrWrong)
    if sum(allRightOrWrong(ii,:)) == size(allRightOrWrong,2)
        totalRrightOrWrong(ii,1) = 1;
    end
end
end