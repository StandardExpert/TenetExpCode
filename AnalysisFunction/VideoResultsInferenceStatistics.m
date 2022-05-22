function VideoResultsInferenceStatistics()
%% ------------------------------------------------------------------------
%                               0.初始化
%--------------------------------------------------------------------------
clear;clc;
%---------------获取所有文档
allStatisticOutcomeFile = dir(['G:\tenet\Capture\','*StatisticOutcome.mat']);

%% ------------------------------------------------------------------------
%                           1.读取与描述性统计
%--------------------------------------------------------------------------
%---------------准备整体数据表
allForwardHesitateTimeCell = cell(1,length(allStatisticOutcomeFile));
allBackwardHesitateTimeCell = cell(1,length(allStatisticOutcomeFile));
%---------------循环读取数据
for fileIndex = 1:length(allStatisticOutcomeFile)
    tempFileAbsolutePath = [allStatisticOutcomeFile(fileIndex).folder '\' allStatisticOutcomeFile(fileIndex).name];
    load(tempFileAbsolutePath,'blockInformation');
    %----------对在决策点范围内的时间分训练次数求和
    trainNumber = length(blockInformation);
    trainHesitatingPointStayTime = zeros(1,length(trainNumber));%这里装的是在决策点呆的时长
    trainFrameNumber = zeros(1,length(trainNumber));%这里装的是在总时长
    forwardTimeListCount = 0;
    backwardTimeListCount = 0;
    for trainIndex = 1:trainNumber
        trainHesitatingPointStayTime(trainIndex) = sum(blockInformation(trainIndex).detactInformation);
        trainFrameNumber(trainIndex) = blockInformation(trainIndex).frameIndexNumber;
        switch blockInformation(trainIndex).classification
            case 'forward'
                forwardTimeListCount = forwardTimeListCount + 1;
            case 'backward'
                backwardTimeListCount = backwardTimeListCount + 1;
        end
    end
    %----------保存到整体数据表中
    allForwardHesitateTimeCell{fileIndex} = trainHesitatingPointStayTime(1:forwardTimeListCount);
    allBackwardHesitateTimeCell{fileIndex} = trainHesitatingPointStayTime(trainNumber - backwardTimeListCount + 1:end);
    %----------出图
    %-----准备figure
    figureHandle = figure(1);
    set(figureHandle,'Color','w','menubar','none','toolbar','none','InvertHardCopy','off');
    axes(figureHandle,'Units','pixels');
    hold on;
    if forwardTimeListCount > 0
        forwardHesitatingList = trainHesitatingPointStayTime(1:forwardTimeListCount);
        forwardTotalList = trainFrameNumber(1:forwardTimeListCount);
        plot(forwardHesitatingList, ...
            "Color",[0.00,0.45,0.74], ...
            "LineStyle","-", ...
            "Marker",'.', ...
            "MarkerSize",20 ...
            );
        plot(forwardTotalList, ...
            "Color",[0.00,0.45,0.74], ...
            "LineStyle","--", ...
            "Marker",'o', ...
            "MarkerSize",6 ...
            );
        %legend('Forward Desition Time','Forward Total Time');
    end
    if backwardTimeListCount > 0
        backwardHesitatingList = trainHesitatingPointStayTime(trainNumber - backwardTimeListCount + 1:end);
        backwardTotalList = trainFrameNumber(trainNumber - backwardTimeListCount + 1:end);
        plot(backwardHesitatingList, ...
            "Color",[0.90,0.00,0.00], ...
            "LineStyle","-", ...
            "Marker",'.', ...
            "MarkerSize",20 ...
            );
        plot(backwardTotalList, ...
            "Color",[0.90,0.00,0.00], ...
            "LineStyle","--", ...
            "Marker",'o', ...
            "MarkerSize",6 ...
            );
        %legend('Backward Desition Time','Backward Total Time');
    end
    legend('Forward Desition Time','Forward Total Time','Backward Desition Time','Backward Total Time');
    xlabel('Training Times');
    ylabel('Sample Frame Count');
    print(strrep(tempFileAbsolutePath,'.mat',''), '-dpng', '-r600');
    hold off;
    close all;
    %pause();
end
%% ------------------------------------------------------------------------
%                               2.整体分析
%--------------------------------------------------------------------------
allForwardCount = 0;
allBackwardCount = 0;
%---------------标准化放缩
for fileIndex = 1:length(allStatisticOutcomeFile)
    %----------提取这个人的数据，获取最大值最小值
    tempForwardCount = length(allForwardHesitateTimeCell{fileIndex});
    tempBackwardCount = length(allBackwardHesitateTimeCell{fileIndex});
    allForwardCount = allForwardCount + tempForwardCount;
    allBackwardCount = allBackwardCount + tempBackwardCount;

    tempPersonData = [allForwardHesitateTimeCell{fileIndex} allBackwardHesitateTimeCell{fileIndex}];
    tempMinData = min(tempPersonData);
    tempMaxData = max(tempPersonData);
    %----------先乘除放缩，后加减平移
    deltaRate = (1000-100) / (tempMaxData - tempMinData);
    tempPersonData = tempPersonData * deltaRate;
    deltaTranslation = 100 - min(tempPersonData);
    tempPersonData = tempPersonData + deltaTranslation;
    %----------放回原来的Cell中
    allForwardHesitateTimeCell{fileIndex} = tempPersonData(1:tempForwardCount);
    allBackwardHesitateTimeCell{fileIndex} = tempPersonData(tempForwardCount + 1:end);
end

%---------------整体合并
%数据结构是两行，第一行是数据，第二行是训练次数。
allForwardHesitateTimeArray = zeros(allForwardCount,2);
allBackwardHesitateTimeArray = zeros(allBackwardCount,2);
forwardAssignmentCounter = 0;%其实是写入指针
backwardAssignmentCounter = 0;

for fileIndex = 1:length(allStatisticOutcomeFile)
    %----------forward
    tempForwardCount = length(allForwardHesitateTimeCell{fileIndex});
    allForwardHesitateTimeArray(forwardAssignmentCounter+1:forwardAssignmentCounter + tempForwardCount,1) = ...
        [1:tempForwardCount];
    allForwardHesitateTimeArray(forwardAssignmentCounter+1:forwardAssignmentCounter + tempForwardCount,2) = ...
        allForwardHesitateTimeCell{fileIndex};

    forwardAssignmentCounter = forwardAssignmentCounter + tempForwardCount;
    %----------backward
    tempBackwardCount = length(allBackwardHesitateTimeCell{fileIndex});
    allBackwardHesitateTimeArray(backwardAssignmentCounter+1:backwardAssignmentCounter + tempBackwardCount,1) = ...
        [1:tempBackwardCount];
    allBackwardHesitateTimeArray(backwardAssignmentCounter+1:backwardAssignmentCounter + tempBackwardCount,2) = ...
        allBackwardHesitateTimeCell{fileIndex};
    backwardAssignmentCounter = backwardAssignmentCounter + tempBackwardCount;
    pause();
end
%---------------画图检验所有数据
% plot(allForwardHesitateTimeArray(2,:),allForwardHesitateTimeArray(1,:), ...
%     "LineStyle","none", ...
%     "Marker",".", ...
%     "MarkerSize",20 ...
%     );
% hold on;
% plot(allBackwardHesitateTimeArray(2,:),allBackwardHesitateTimeArray(1,:), ...
%     "LineStyle","none", ...
%     "Marker",".", ...
%     "MarkerSize",20 ...
%     );
% hold on;
ifDrawPlot = true;
saveOutcomeFolder = 'G:\tenet\Capture';
fitParameterArray = [1000, 0 ,100];
MonteCarloMethodRepeatTime = 1000;
sig = InverseProportionalClassKSGoodnessFitTest( ...
    allForwardHesitateTimeArray, ...
    allBackwardHesitateTimeArray, ...
    fitParameterArray, ...
    MonteCarloMethodRepeatTime, ...
    ifDrawPlot, ...
    saveOutcomeFolder ...
    );













end