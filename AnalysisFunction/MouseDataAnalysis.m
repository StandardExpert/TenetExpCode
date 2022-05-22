%Mouse data analysis
% mouse1是左上笼 0.5
% mouse2是左上笼 2
% mouse3是左上笼 2.5
% mouse4是右上笼 左1
% mouse5是右上笼 右2
% mouse6是右上笼 左2
clear;clc;
%--------------------------------------------------------------------------
%                              0.原始数据
%--------------------------------------------------------------------------
%---------------Forward
mouse1ForwardData = [204,   90,     53,     71,     27.56,  28.93,  80.26,  26.37,  27.56,  22.50,  14.23];
mouse2ForwardData = [59,    30,     35,     28,     10.05,  7.75,   25,     8.25,   14.93,  7.31,   17.31];
mouse3ForwardData = [95,    41,     36,     64,     14.87,  17.81,  14.06,  10,     12.56,  37.24,  6.18];
mouse4ForwardData = [33,    17,     7.87,   7.31,   7.56,   5.93,   11.06,  5.26,   8.26];
mouse5ForwardData = [36,    18,     11.08,  15.93,  22.05,  8.81,   11.37,  10.25,  20.68];
mouse6ForwardData = [46,    18,     10.81,  19.81,  13.75,  23.56,  7.31,   8.06,   19.81];
%---------------Backward
mouse1BackwardData = [61.56,    9.06,   17.56,  28.31,  17.56];
mouse2BackwardData = [44.87,    6.62,   8.18,   21.81,  5.18];
mouse3BackwardData = [12.93,    10.87,  10.18,  35.81,  9.24];
mouse4BackwardData = [43.06,    18.18,  11.12,  9.81,   5.31];
mouse5BackwardData = [10.37,    10.81,  13.56,  16.25,  12.06];
mouse6BackwardData = [30.93,    5.93,   11.31,  9.37,   5.45];
%---------------All data cell
%一行一个鼠
AllDataCell = {
    mouse1ForwardData,mouse1BackwardData;
    mouse2ForwardData,mouse2BackwardData;
    mouse3ForwardData,mouse3BackwardData;
    mouse4ForwardData,mouse4BackwardData;
    mouse5ForwardData,mouse5BackwardData;
    mouse6ForwardData,mouse6BackwardData
    };

%--------------------------------------------------------------------------
%                               1.KS数据
%--------------------------------------------------------------------------
allForwardCount = 0;
allBackwardCount = 0;

%---------------标准化放缩
for mouseIndex = 1:size(AllDataCell,1)
    %----------提取这个鼠的数据，获取最大值最小值
    tempForwardCount = length(AllDataCell{mouseIndex,1});
    tempBackwardCount = length(AllDataCell{mouseIndex,2});
    allForwardCount = allForwardCount + tempForwardCount;
    allBackwardCount = allBackwardCount + tempBackwardCount;
    tempMouseData = [AllDataCell{mouseIndex,1} AllDataCell{mouseIndex,2}];
    tempMinData = min(tempMouseData);
    tempMaxData = max(tempMouseData);
    %----------先乘除放缩，后加减平移
    deltaRate = (1000-100) / (tempMaxData - tempMinData);
    tempMouseData = tempMouseData * deltaRate;
    deltaTranslation = 100 - min(tempMouseData);
    tempMouseData = tempMouseData + deltaTranslation;
    %----------放回原来的Cell中
    AllDataCell{mouseIndex,1} = tempMouseData(1:tempForwardCount);
    AllDataCell{mouseIndex,2} = tempMouseData(tempForwardCount + 1:end);
end

%---------------数据编程KS统计用数据
for mouseIndex = 1:size(AllDataCell,1)
    AllDataCell{mouseIndex,1} = GenerateKSDataArray(AllDataCell{mouseIndex,1});
    AllDataCell{mouseIndex,2} = GenerateKSDataArray(AllDataCell{mouseIndex,2});
end

%---------------All get in a matrix
Group1Matrix = zeros(allForwardCount,2);
Group2Matrix = zeros(allBackwardCount,2);
pointerPositionForward = 1;
pointerPositionBackward = 1;
for mouseIndex = 1:size(AllDataCell,1)
    %----------获取长度
    tempForwardCount = length(AllDataCell{mouseIndex,1});
    tempBackwardCount = length(AllDataCell{mouseIndex,2});
    %----------赋值
    Group1Matrix(pointerPositionForward:pointerPositionForward + tempForwardCount - 1,:) = AllDataCell{mouseIndex,1};
    Group2Matrix(pointerPositionBackward:pointerPositionBackward + tempBackwardCount - 1,:) = AllDataCell{mouseIndex,2};
    %----------指针移动
    pointerPositionForward = pointerPositionForward + tempForwardCount;
    pointerPositionBackward = pointerPositionBackward + tempBackwardCount;
end
% plot(Group2Matrix(:,1),Group2Matrix(:,2), ...
%     "Marker",'.', ...
%     "MarkerSize",15,...
%     "LineStyle","none",...
%     "MarkerEdgeColor",[0, 0.69, 0.94]...
%     );


%--------------------------------------------------------------------------
%                               2.类KS统计
%--------------------------------------------------------------------------
ifDrawPlot = true;
saveOutcomeFolder = 'G:\tenet\Data\Rodent';
fitParameterArray = [1000, 0 ,100];
MonteCarloMethodRepeatTime = 1000;
saveOutcomeIndex = 0;
sig = InverseProportionalClassKSGoodnessFitTest( ...
    Group1Matrix, ...
    Group2Matrix, ...
    fitParameterArray, ...
    MonteCarloMethodRepeatTime, ...
    ifDrawPlot, ...
    saveOutcomeFolder, ...
    saveOutcomeIndex ...
    );
%--------------------------------------------------------------------------
%                        3.单独每个小鼠的数据统计
%--------------------------------------------------------------------------
sigList = zeros(1,size(AllDataCell,1));
for mouseIndex = 1:size(AllDataCell,1)
    tempGroup1Matrix = AllDataCell{mouseIndex,1};
    tempGroup2Matrix = AllDataCell{mouseIndex,2};
    ifDrawPlot = true;
    saveOutcomeFolder = 'G:\tenet\Data\Rodent';
    fitParameterArray = [1000, 0 ,100];
    MonteCarloMethodRepeatTime = 1000;
    saveOutcomeIndex = mouseIndex;
    sigList(mouseIndex) = InverseProportionalClassKSGoodnessFitTest( ...
        tempGroup1Matrix, ...
        tempGroup2Matrix, ...
        fitParameterArray, ...
        MonteCarloMethodRepeatTime, ...
        ifDrawPlot, ...
        saveOutcomeFolder, ...
        saveOutcomeIndex ...
        );
end
