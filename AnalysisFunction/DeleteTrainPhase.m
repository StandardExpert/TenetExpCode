function totalAnswerArray = DeleteTrainPhase(totalAnswerArray,judgeList)
deleteMarker = [];
for ii = 1:size(totalAnswerArray,1)
    if strcmp(totalAnswerArray{ii,judgeList},'train')
        deleteMarker = [deleteMarker ii];
    end
end
totalAnswerArray(deleteMarker,:) = [];
end