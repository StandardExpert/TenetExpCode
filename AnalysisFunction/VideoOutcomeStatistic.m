function VideoOutcomeStatistic(videoFileName,bigMapFolder,ifGenerateVideo)
%VideoOutcomeStatistic(videoFileName,bigMapFolder,ifGenerateVideo)
%用来对结果数据进行简单处理，并进行统计和制作展示视频.
%% ------------------------------------------------------------------------
%                                0.初始化
%--------------------------------------------------------------------------
%clear;close all;clc;
%---------------基本参数
%ifGenerateVideo = true;
%videoFileName = 'G:\tenet\demoVideo.mp4';
%bigMapFolder = 'G:\tenet\Capture\map';
continueSeconds = 1;
trustThreshold = 0.9;
%----------设置统计探测区块
%每一行是起点的x1 y1，终点的x2 y2
detectRange = zeros(7,4);
detectRange(1,:) = [309 309 408 397];
detectRange(2,:) = [560 437 611 582];
detectRange(3,:) = [417 378 498 483];
detectRange(4,:) = [456 448 550 568];
detectRange(5,:) = [453 576 500 612];
detectRange(6,:) = [193 448 262 612];
detectRange(7,:) = [234 531 265 614];
startRange = [309 309 408 397];
endRange = [162 576 228 614];

%---------------计算二级参数
%----------读取视频基本信息
videoObject = VideoReader(videoFileName);
frameRate = round(videoObject.FrameRate);
%----------查找视频分析结果
matFileName = strrep(videoFileName,'.mp4','.mat');
outcomeFileName = strrep(videoFileName,'.mp4','StatisticOutcome.mat');
if ~exist(matFileName,'file')
    return;
end
load(matFileName,"videoOutcome");

%----------计算可能用到的帧参数
%----------删除空行
deleteLineMark = (videoOutcome(:,1) == 0);
videoOutcome(deleteLineMark,:) = [];
frameStep = videoOutcome(2,1) - videoOutcome(1,1);
frameInvolvedNumberPersecond = round(frameRate/frameStep);
continueFrameInvolvedNumber =frameInvolvedNumberPersecond * continueSeconds;
%% ------------------------------------------------------------------------
%                               1.统计分析
%--------------------------------------------------------------------------
%---------------预处理
%----------信度bug调整
videoOutcome(videoOutcome(:,end) == 0,end) = -1;
%----------剔除与插补
%有啥好方法？反正没想到，先不剔除了。

%---------------切分组块
%-1标记连片超过1s我们认为这个组块结束了
%生成blockInformation这个结构体，结构体中包含了很多字段：
%blockInformation(blockIndex).classification = "forward" | "backward" | "recallTheMap";
%blockInformation(blockIndex).frameRange = [startFrame endFrame];
%blockInformation(blockIndex).detactInformation = 1行7列的停留时间;
continuousLength = (continueSeconds*frameRate)/frameStep;
%----------二值化，找到置信度正常的。
%-----找-1，现在true代表-1
binaryLineConfidence = (videoOutcome(:,end) == -1);%find(binaryLineConfidence == 1)
[~, countNotPlay] = bwlabel(binaryLineConfidence, 4);
%-----找非-1，现在true代表非-1
binaryLineConfidence = (binaryLineConfidence == false);%find(binaryLineConfidence == 1)
[~, countPlay] = bwlabel(binaryLineConfidence, 4);
while true
    %-----找-1，现在true代表-1
    binaryLineConfidence = (binaryLineConfidence == false);%find(binaryLineConfidence == 1)
    [notPlayLabel, newCountNotPlay] = bwlabel(binaryLineConfidence, 4);%find(notPlayLabel == 1)
    %---删去极小值
    notPlayTourList = zeros(newCountNotPlay,1);
    for tourIndex = 1:newCountNotPlay
        notPlayTourList(tourIndex) = sum(notPlayLabel == tourIndex);
        if notPlayTourList(tourIndex) < continuousLength
            binaryLineConfidence(notPlayLabel == tourIndex) = false;
        end
    end

    %-----找非-1，现在true代表非-1
    binaryLineConfidence = (binaryLineConfidence == false);%find(binaryLineConfidence == 1)
    [playLabel, newCountPlay] = bwlabel(binaryLineConfidence, 4);%find(playLabel == 1)
    %---删去极小值
    playTourList = zeros(newCountPlay,1);
    for tourIndex = 1:newCountNotPlay
        playTourList(tourIndex) = sum(playLabel == tourIndex);
        if playTourList(tourIndex) < 10*continuousLength%真正玩的时间肯定很长
            binaryLineConfidence(playLabel == tourIndex) = false;
        end
    end

    %-----判断是否处理干净
    if (newCountNotPlay == countNotPlay) && (newCountPlay == countPlay)
        break;
    else
        countNotPlay = newCountNotPlay;
        countPlay = newCountPlay;
    end
end
%整合结果如下：
%objectsNotPlay
%countNotPlay
%objectsPlay
%countPlay
%binaryLineConfidence，现在true代表在玩

%---------------对组块分析
%生成blockInformation这个结构体，结构体中包含了很多字段：
%blockInformation(blockIndex).classification = 'forward' | 'backward' | 'recallTheMap';4
%blockInformation(blockIndex).frameRange = [startFrame endFrame];
%blockInformation(blockIndex).frameIndexNumber=endFrameLine - startFrameLine + 1;
%blockInformation(blockIndex).detactInformation = 1行7列的停留时间;
blockInformation(1:countPlay) = struct( ...
    'classification','', ...
    'frameRange',[0 0], ...
    'detactInformation',zeros(1,7) ...
    );

for blockIndex = 1:countPlay
    %----------找起止点
    startFrameLine = find(playLabel == blockIndex, 1, 'first');
    endFrameLine = find(playLabel == blockIndex, 1, 'last');
    startFrame = videoOutcome(startFrameLine,1);
    endFrame = videoOutcome(endFrameLine,1);
    blockInformation(blockIndex).frameRange = [startFrame endFrame];
    blockInformation(blockIndex).frameIndexNumber = endFrameLine - startFrameLine + 1;
    %----------判断游玩状态
    %这2s基本都在起点区域或者终点区域
    ifForward = [0 0];
    startPointList = videoOutcome(startFrameLine:startFrameLine+continueFrameInvolvedNumber,4:5);
    ifForward(1) = IfInTheRange(startPointList,startRange,'trustThreshold',trustThreshold);
    endPointList = videoOutcome(endFrameLine:-1:endFrameLine-continueFrameInvolvedNumber,4:5);
    ifForward(2) = IfInTheRange(endPointList,endRange,'trustThreshold',trustThreshold);

    ifBackward = [0 0];
    startPointList = videoOutcome(startFrameLine:startFrameLine+continueFrameInvolvedNumber,4:5);
    ifBackward(1) = IfInTheRange(startPointList,endRange,'trustThreshold',trustThreshold);
    endPointList = videoOutcome(endFrameLine:-1:endFrameLine-continueFrameInvolvedNumber,4:5);
    ifBackward(2) = IfInTheRange(endPointList,startRange,'trustThreshold',trustThreshold);

    if ifForward
        blockInformation(blockIndex).classification = 'forward';
    elseif ifBackward
        blockInformation(blockIndex).classification = 'backward';
    elseif (ifForward~=ifBackward)
        blockInformation(blockIndex).classification = 'recallTheMap';
    end

    %----------统计
    for detectRangeIndex = 1:size(detectRange,1)
        ifInTheRangeList = IfInTheRange(videoOutcome(startFrameLine:end,4:5),detectRange(detectRangeIndex,:));
        blockInformation(blockIndex).detactInformation(detectRangeIndex) = ...
            sum(ifInTheRangeList) * frameStep / frameRate;
    end

end
save(outcomeFileName,'blockInformation','-mat');
%% ------------------------------------------------------------------------
%                               2.视频生成
%--------------------------------------------------------------------------
if ifGenerateVideo
    %----------读取大地图
    bigMapFile = dir([bigMapFolder '\*.png']);
    bigMapFileName = cell(length(bigMapFile),1);
    bigMapImage = cell(1,length(bigMapFile));
    for ii = 1:length(bigMapFile)
        bigMapFileName{ii} = [bigMapFile(ii).folder '\' bigMapFile(ii).name];
        bigMapImage{ii} = imread(bigMapFileName{ii});
    end
    %----------生成figure
    figureHandle = figure();
    set(figureHandle, ...
        'InvertHardCopy','off', ...
        'Color','w', ...
        'menubar','none', ...
        'toolbar','none', ...
        'Units','pixels', ...
        'Position',[20,20,size(bigMapImage{1},2),size(bigMapImage{1},1)] ...
        );%,'menubar','none','toolbar','none'
    axesHandle = axes();
    set(axesHandle, ...
        'Units','pixels', ...
        'Position',[0,0,size(bigMapImage{1},2),size(bigMapImage{1},1)] ...
        );
    axis off;
    %----------生成视频文件夹
    videoFolderName = strrep(videoFileName,'.mp4','StatisticOutcome');
    if ~exist(videoFolderName,'dir')
        mkdir(videoFolderName);
    end

    for blockIndex = 1:countPlay
        %-----生成block文件夹
        tempBlockFolderName = [videoFolderName '\' num2str(blockIndex) blockInformation(blockIndex).classification];
        if ~exist(tempBlockFolderName,'dir')
            mkdir(tempBlockFolderName);
        end
        %-----生成画面
        frameIndex = 1;
        startFrameLine = find(videoOutcome(:,1) == blockInformation(blockIndex).frameRange(1));
        %---初始画面
        point = videoOutcome(startFrameLine,4:5);
        imageHandle = imshow(bigMapImage{videoOutcome(startFrameLine,2)},"Parent",axesHandle);
        hold on;
        plotHandle = plot(point(2),point(1), ...
            "LineStyle",'-', ...
            "LineWidth",0.5, ...
            "Color",[0 0 0.8], ...
            "Marker",'.', ...
            "MarkerSize",3, ...
            "MarkerFaceColor",[0.8 0 0], ...
            "MarkerEdgeColor",[0.8 0 0], ...
            'Parent',axesHandle ...
            );
        scatterHandle = scatter(axesHandle,point(2),point(1),24, ...
            'MarkerFaceColor','none', ...
            'MarkerEdgeColor','r', ...
            "MarkerEdgeAlpha",1 ...
            );
        hold off;
        for blockFrameIndex = startFrameLine : startFrameLine + blockInformation(blockIndex).frameIndexNumber - 1
            point = videoOutcome(blockFrameIndex,4:5);
            if sum(point<=0)
                continue;
            end
            %---修改背景图和点的参数
            imageHandle.CData = bigMapImage{videoOutcome(blockFrameIndex,2)};
            scatterHandle.XData = point(2);
            scatterHandle.YData = point(1);
            %---保存帧
            frameName = [tempBlockFolderName '\' num2str(frameIndex) '.png'];
            saveas(figureHandle,frameName);%分辨率始终摆脱不了放大比例...
            %getImage不行，它只能获取Figure中的image对象。
            %figureImage = getimage(figureHandle);imshow(figureImage);
            %print(frameName, '-dpng', '-r600');
            %---尾部迭代
            plotHandle.XData = [plotHandle.XData point(2)];
            plotHandle.YData = [plotHandle.YData point(1)];
            frameIndex = frameIndex + 1;
            pause(0.05);
        end
    end
    close all;
end

end