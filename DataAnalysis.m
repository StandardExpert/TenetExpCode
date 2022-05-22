function DataAnalysis()
% Author 李博华
% Time 2022/1/8 9:45
% 程序逻辑：
% 1.读取：读取所有文件名。
% 2.分类：挑选符合分类的文件名形成列表。
% 3.循环读取数据：trial循环，Reaction位置循环。
% 4.计算：真RT版本的正误、反应时。RT0版本的正误，反应时。

%% ------------------------------------------------------------------------
%                      0. Rearrange the enviorment
%--------------------------------------------------------------------------
%---------------打开工作目录
mFilePath = which('DataAnalysis');
slashPosition = strfind(mFilePath,'\');
cd(mFilePath( 1: (slashPosition(end)-1) ));
clear;close all;sca;clc;

%---------------基本参数
rootDir = pwd;
dataFolder = [rootDir '\Data'];
saveOutcomeFolder = [dataFolder '\ProcessingResults'];
cd(dataFolder);
allFileName = dir();

blueColor = [0,0.45,0.74];
redColor = [1.00,0.19,0.13];
yellowColor = [0.93,0.69,0.13];
%删去.和..
deleteMarker = zeros(1,2);deleteIndex = 1;
for ii = 1:size(allFileName,1)
    if strcmp(allFileName(ii).name, '.') || strcmp(allFileName(ii).name, '..')
        deleteMarker(deleteIndex) = ii;
        deleteIndex = deleteIndex + 1;
    end
end
allFileName(deleteMarker,:) = [];

%按照实验分类
fileListTenetGeometry = {};fileListIndexTenetGeometry = 1;
fileListTenetScale = {};fileListIndexTenetScale = 1;
fileListTenetSpatial = {};fileListIndexTenetSpatial = 1;
for ii = 1:size(allFileName,1)
    if ~isempty( strfind(allFileName(ii).name, 'TenetGeometry') )
        fileListTenetGeometry{fileListIndexTenetGeometry} = [allFileName(ii).folder '\' allFileName(ii).name];
        fileListIndexTenetGeometry = fileListIndexTenetGeometry + 1;
    elseif ~isempty( strfind(allFileName(ii).name, 'TenetScale') )
        fileListTenetScale{fileListIndexTenetScale} = [allFileName(ii).folder '\' allFileName(ii).name];
        fileListIndexTenetScale = fileListIndexTenetScale + 1;
    elseif ~isempty( strfind(allFileName(ii).name, 'TenetSpatial') )
        fileListTenetSpatial{fileListIndexTenetSpatial} = [allFileName(ii).folder '\' allFileName(ii).name];
        fileListIndexTenetSpatial = fileListIndexTenetSpatial + 1;
    end
end

%% ------------------------------------------------------------------------
%                            1. TenetGeometry
%--------------------------------------------------------------------------
%--------------保存每一个人的均值。正误、RT、STDRT、-RT0、STD-RT0
% 1 2是总Trial的正确率，
% 3 4是每一位的正确率，
% 5 6是RT，
% 7 8是STDRT，
% 9 10是RT0，
% 11 12是STDRT0，
% 13 14是deltaRT，
% 15 16是allSTDDeltaRTArray
allGeometryParticipantMeanData = cell( length(fileListTenetGeometry), 2*8);
for participantIndex = 1:length(fileListTenetGeometry)
    load(fileListTenetGeometry{participantIndex},'totalAnswerArray','participantNumber');
    %删除练习阶段，标志列是2
    totalAnswerArray = DeleteTrainPhase(totalAnswerArray,2);
    %正背、倒背分开，标志列是4
    [forwardData,backwardData] = SeparateData(totalAnswerArray,4);
    
    for trialType = 1:2
        if trialType == 1
            tempAnswerArray = forwardData;
        elseif trialType == 2
            tempAnswerArray = backwardData;
        end
        %数据合并成矩阵
        allStimArray = CollectCellData2Mat(tempAnswerArray(:,3));
        allTargetType = CollectCellData2Mat(tempAnswerArray(:,4));
        allReactionArray = CollectCellData2Mat(tempAnswerArray(:,5));
        allRTArray = CollectCellData2Mat(tempAnswerArray(:,6));
        allRT0Array = allRTArray - CollectCellData2Mat(tempAnswerArray(:,7));

        %-----每一位的正确率
        [totalRrightOrWrong,allRightOrWrong] = JudgeRightOrWrong(allStimArray,allTargetType,allReactionArray);
        meanCorrectRate = mean(allRightOrWrong);
        meanTrialCorrectRate = mean(totalRrightOrWrong);
        %-----每一位的反应时
        allMeanRTArray = mean(allRTArray);
        allSTDRTArray = std(allRTArray);
        %-----每一位的RT0反应时
        allMeanRT0Array = mean(allRT0Array);
        allSTDRT0Array = std(allRT0Array);
        %-----每次反应时的差值
        deltaRTArray = GetDeltaRT(allRTArray);
        allMeanDeltaRTArray = mean(deltaRTArray);
        allSTDDeltaRTArray = std(deltaRTArray);
        %保存这位被试的均值,1 2是总Trial的正确率,3 4 是每一位的正确率，5 6是RT，7 8是STDRT, 9 10是RT0，11 12是STDRT0，
        %13 14是deltaRT，15 16是allSTDDeltaRTArray
        allGeometryParticipantMeanData{participantIndex,0*2 + trialType} = meanTrialCorrectRate;
        allGeometryParticipantMeanData{participantIndex,1*2 + trialType} = meanCorrectRate;
        allGeometryParticipantMeanData{participantIndex,2*2 + trialType} = allMeanRTArray;
        allGeometryParticipantMeanData{participantIndex,3*2 + trialType} = allSTDRTArray;
        allGeometryParticipantMeanData{participantIndex,4*2 + trialType} = allMeanRT0Array;
        allGeometryParticipantMeanData{participantIndex,5*2 + trialType} = allSTDRT0Array;
        allGeometryParticipantMeanData{participantIndex,6*2 + trialType} = allMeanDeltaRTArray;
        allGeometryParticipantMeanData{participantIndex,7*2 + trialType} = allSTDDeltaRTArray;
    end
    %-----画图
    %顺向：正确率，RT，-RT0，deltaRT
    %逆向：正确率，RT，-RT0，deltaRT
    %plotName = [participantNumber ' Geometry'];
    %tempSaveOutcomeFolder = [saveOutcomeFolder '\Geometry'];
    %DrawRTErrorBar(tempSaveOutcomeFolder,plotName,allGeometryParticipantMeanData(participantIndex,:));
end

%---------------整体数据合并
% 1 2是总Trial的正确率，
% 3 4是每一位的正确率，
% 5 6是RT，
% 7 8是STDRT，
% 9 10是RT0，
% 11 12是STDRT0，
% 13 14是deltaRT，
% 15 16是allSTDDeltaRTArray
mergeGeometryParticipantMeanData = cell(1, 2*8);
%----------求均值
meanColumnList = [1 2 3 4 5 6 9 10 13 14];
for ii = 1:length(meanColumnList)
    columnIndex = meanColumnList(ii);
    %-----数据合并成矩阵
    tempData=zeros(length(fileListTenetGeometry),length(allGeometryParticipantMeanData{1,columnIndex}));
    for participantIndex = 1:length(fileListTenetGeometry)
        tempData(participantIndex,:) = allGeometryParticipantMeanData{participantIndex,columnIndex};
    end
    %-----对合并后的矩阵进行计算、赋值
    mergeGeometryParticipantMeanData{columnIndex} = mean(tempData,1);
end
%----------求STD
stdColumnList = [7 8 11 12 15 16];
for ii = 1:length(stdColumnList)%T了那个先想好在做的1号。201811940110
    %先把基本数值拉出来
    columnIndex = stdColumnList(ii)-2;
    %-----数据合并成矩阵
    tempData=zeros(length(fileListTenetGeometry),length(allGeometryParticipantMeanData{1,columnIndex}));
    for participantIndex = 2:length(fileListTenetGeometry)
        tempData(participantIndex,:) = allGeometryParticipantMeanData{participantIndex,columnIndex};
    end
    %列号变回STD要保存的列号
    columnIndex = columnIndex + 2;
    %-----对合并后的矩阵进行计算、赋值
    mergeGeometryParticipantMeanData{columnIndex} = std(tempData,1);
end
%----------画图
plotName = ['Merge' 'Geometry'];
tempSaveOutcomeFolder = [saveOutcomeFolder '\Geometry'];
DrawRTErrorBar(tempSaveOutcomeFolder,plotName,mergeGeometryParticipantMeanData(1,:));

%% ------------------------------------------------------------------------
%                             2. TenetScale
%--------------------------------------------------------------------------
allScaleParticipantMeanData = cell( length(fileListTenetScale), 2*8);
for participantIndex = 1:length(fileListTenetScale)
    load(fileListTenetScale{participantIndex},'totalAnswerArray','participantNumber');
    %删除练习阶段，标志列是2
    totalAnswerArray = DeleteTrainPhase(totalAnswerArray,2);
    %正背、倒背分开，标志列是4
    [forwardData,backwardData] = SeparateData(totalAnswerArray,4);
    
    for trialType = 1:2
        if trialType == 1
            tempAnswerArray = forwardData;
        elseif trialType == 2
            tempAnswerArray = backwardData;
        end
        %数据合并成矩阵
        allStimArray = CollectCellData2Mat(tempAnswerArray(:,3));
        allTargetType = CollectCellData2Mat(tempAnswerArray(:,4));
        allCorrectAnswerArray = CollectCellData2Mat(tempAnswerArray(:,5));
        allReactionArray = CollectCellData2Mat(tempAnswerArray(:,7));
        allRTArray = CollectCellData2Mat(tempAnswerArray(:,8));
        allRT0Array = CollectCellData2Mat(tempAnswerArray(:,9));

        %-----每一位的正确率
        [totalRrightOrWrong,allRightOrWrong] = JudgeRightOrWrong(allCorrectAnswerArray,allTargetType,allReactionArray);
        meanCorrectRate = mean(allRightOrWrong);
        meanTrialCorrectRate = mean(totalRrightOrWrong);
        %-----每一位的反应时
        allMeanRTArray = mean(allRTArray);
        allSTDRTArray = std(allRTArray);
        %-----每一位的RT0反应时
        allMeanRT0Array = mean(allRT0Array);
        allSTDRT0Array = std(allRT0Array);
        %-----每次反应时的差值
        %deltaRTArray = GetDeltaRT(allRTArray);
        %allMeanDeltaRTArray = mean(deltaRTArray);
        %allSTDDeltaRTArray = std(deltaRTArray);
        %保存这位被试的均值,1 2是总Trial的正确率,3 4 是每一位的正确率，5 6是RT，7 8是STDRT, 9 10是RT0，11 12是STDRT0，
        %13 14是deltaRT，15 16是allSTDDeltaRTArray
        allScaleParticipantMeanData{participantIndex,0*2 + trialType} = meanTrialCorrectRate;
        allScaleParticipantMeanData{participantIndex,1*2 + trialType} = meanCorrectRate;
        allScaleParticipantMeanData{participantIndex,2*2 + trialType} = allMeanRTArray;
        allScaleParticipantMeanData{participantIndex,3*2 + trialType} = allSTDRTArray;
        allScaleParticipantMeanData{participantIndex,4*2 + trialType} = allMeanRT0Array;
        allScaleParticipantMeanData{participantIndex,5*2 + trialType} = allSTDRT0Array;
        %allScaleParticipantMeanData{participantIndex,6*2 + trialType} = allMeanDeltaRTArray;
        %allScaleParticipantMeanData{participantIndex,7*2 + trialType} = allSTDDeltaRTArray;
    end
    %-----画图
    %顺向：正确率，RT，-RT0，deltaRT
    %逆向：正确率，RT，-RT0，deltaRT
    %plotName = [participantNumber ' Scale'];
    %tempSaveOutcomeFolder = [saveOutcomeFolder '\Scale'];
    %DrawRTErrorBar(tempSaveOutcomeFolder,plotName,allScaleParticipantMeanData(participantIndex,:));
end
%---------------整体数据合并
% 1 2是总Trial的正确率，
% 3 4是每一位的正确率，
% 5 6是RT，
% 7 8是STDRT，
% 9 10是RT0，
% 11 12是STDRT0，
% 13 14是deltaRT，
% 15 16是allSTDDeltaRTArray
mergeScaleParticipantMeanData = cell(1, 2*6);
%----------求均值
meanColumnList = [1 2 3 4 5 6 9 10];
for ii = 1:length(meanColumnList)
    columnIndex = meanColumnList(ii);
    %-----数据合并成矩阵
    tempData=zeros(length(fileListTenetGeometry),length(allScaleParticipantMeanData{1,columnIndex}));
    for participantIndex = 1:length(fileListTenetGeometry)
        tempData(participantIndex,:) = allScaleParticipantMeanData{participantIndex,columnIndex};
    end
    %-----对合并后的矩阵进行计算、赋值
    mergeScaleParticipantMeanData{columnIndex} = mean(tempData,1);
end
%----------求STD
stdColumnList = [7 8 11 12];
for ii = 1:length(stdColumnList)
    %先把基本数值拉出来
    columnIndex = stdColumnList(ii)-2;
    %-----数据合并成矩阵
    tempData=zeros(length(fileListTenetGeometry),length(allScaleParticipantMeanData{1,columnIndex}));
    for participantIndex = 1:length(fileListTenetGeometry)
        tempData(participantIndex,:) = allScaleParticipantMeanData{participantIndex,columnIndex};
    end
    %列号变回STD要保存的列号
    columnIndex = columnIndex + 2;
    %-----对合并后的矩阵进行计算、赋值
    mergeScaleParticipantMeanData{columnIndex} = std(tempData,1);
end
%----------画图
plotName = ['Merge' 'Scale'];
tempSaveOutcomeFolder = [saveOutcomeFolder '\Scale'];
DrawRTErrorBar(tempSaveOutcomeFolder,plotName,mergeScaleParticipantMeanData(1,:));


%% ------------------------------------------------------------------------
%                            3. TenetSpatial
%--------------------------------------------------------------------------
allSpatialParticipantMeanData = cell( length(fileListTenetSpatial), 2*8);
for participantIndex = 1:length(fileListTenetSpatial)
    load(fileListTenetSpatial{participantIndex},'totalAnswerArray','participantNumber');
    %删除练习阶段，标志列是2
    totalAnswerArray = DeleteTrainPhase(totalAnswerArray,2);
    %正背、倒背分开，标志列是4
    [forwardData,backwardData] = SeparateData(totalAnswerArray,4);
    
    for trialType = 1:2
        if trialType == 1
            tempAnswerArray = forwardData;
        elseif trialType == 2
            tempAnswerArray = backwardData;
        end
        %数据合并成矩阵
        allStimArray = CollectCellData2Mat(tempAnswerArray(:,3));
        allTargetType = CollectCellData2Mat(tempAnswerArray(:,4));
        allReactionArray = CollectCellData2Mat(tempAnswerArray(:,5));
        allRTArray = CollectCellData2Mat(tempAnswerArray(:,6));
        allRT0Array = allRTArray - CollectCellData2Mat(tempAnswerArray(:,7));

        %-----每一位的正确率
        [totalRrightOrWrong,allRightOrWrong] = JudgeRightOrWrong(allStimArray,allTargetType,allReactionArray);
        meanCorrectRate = mean(allRightOrWrong);
        meanTrialCorrectRate = mean(totalRrightOrWrong);
        %-----每一位的反应时
        allMeanRTArray = mean(allRTArray);
        allSTDRTArray = std(allRTArray);
        %-----每一位的RT0反应时
        allMeanRT0Array = mean(allRT0Array);
        allSTDRT0Array = std(allRT0Array);
        %-----每次反应时的差值
        deltaRTArray = GetDeltaRT(allRTArray);
        allMeanDeltaRTArray = mean(deltaRTArray);
        allSTDDeltaRTArray = std(deltaRTArray);
        %保存这位被试的均值,1 2是总Trial的正确率,3 4 是每一位的正确率，5 6是RT，7 8是STDRT, 9 10是RT0，11 12是STDRT0，
        %13 14是deltaRT，15 16是allSTDDeltaRTArray
        allSpatialParticipantMeanData{participantIndex,0*2 + trialType} = meanTrialCorrectRate;
        allSpatialParticipantMeanData{participantIndex,1*2 + trialType} = meanCorrectRate;
        allSpatialParticipantMeanData{participantIndex,2*2 + trialType} = allMeanRTArray;
        allSpatialParticipantMeanData{participantIndex,3*2 + trialType} = allSTDRTArray;
        allSpatialParticipantMeanData{participantIndex,4*2 + trialType} = allMeanRT0Array;
        allSpatialParticipantMeanData{participantIndex,5*2 + trialType} = allSTDRT0Array;
        allSpatialParticipantMeanData{participantIndex,6*2 + trialType} = allMeanDeltaRTArray;
        allSpatialParticipantMeanData{participantIndex,7*2 + trialType} = allSTDDeltaRTArray;
    end
    %-----画图
    %顺向：正确率，RT，-RT0，deltaRT
    %逆向：正确率，RT，-RT0，deltaRT
    %plotName = [participantNumber ' Spatial'];
    %tempSaveOutcomeFolder = [saveOutcomeFolder '\Spatial'];
    %DrawRTErrorBar(tempSaveOutcomeFolder,plotName,allSpatialParticipantMeanData(participantIndex,:));
end
%---------------整体数据合并
% 1 2是总Trial的正确率，
% 3 4是每一位的正确率，
% 5 6是RT，
% 7 8是STDRT，
% 9 10是RT0，
% 11 12是STDRT0，
% 13 14是deltaRT，
% 15 16是allSTDDeltaRTArray
mergeSpatialParticipantMeanData = cell(1, 2*8);
%----------求均值
meanColumnList = [1 2 3 4 5 6 9 10 13 14];
for ii = 1:length(meanColumnList)
    columnIndex = meanColumnList(ii);
    %-----数据合并成矩阵
    tempData=zeros(length(fileListTenetGeometry),length(allSpatialParticipantMeanData{1,columnIndex}));
    for participantIndex = 1:length(fileListTenetGeometry)
        tempData(participantIndex,:) = allSpatialParticipantMeanData{participantIndex,columnIndex};
    end
    %-----对合并后的矩阵进行计算、赋值
    mergeSpatialParticipantMeanData{columnIndex} = mean(tempData,1);
end
%----------求STD
stdColumnList = [7 8 11 12 15 16];
for ii = 1:length(stdColumnList)
    %先把基本数值拉出来
    columnIndex = stdColumnList(ii)-2;
    %-----数据合并成矩阵
    tempData=zeros(length(fileListTenetGeometry),length(allSpatialParticipantMeanData{1,columnIndex}));
    for participantIndex = 1:length(fileListTenetGeometry)
        tempData(participantIndex,:) = allSpatialParticipantMeanData{participantIndex,columnIndex};
    end
    %列号变回STD要保存的列号
    columnIndex = columnIndex + 2;
    %-----对合并后的矩阵进行计算、赋值
    mergeSpatialParticipantMeanData{columnIndex} = std(tempData,1);
end
%----------画图
plotName = ['Merge' 'Spatial'];
tempSaveOutcomeFolder = [saveOutcomeFolder '\Spatial'];
DrawRTErrorBar(tempSaveOutcomeFolder,plotName,mergeSpatialParticipantMeanData(1,:));


cd(rootDir);
end
