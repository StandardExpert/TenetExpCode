function VideoCoordinate(videoFileName,bigMapFolder)
%VideoCoordinateController是针对Tenet实验制作的游戏位置分析控制器。
% 用来读取视频的每一帧，截取左下角小地图，
%videoFileName
%possibleMainImageNameList
%% ------------------------------------------------------------------------
%                               0.初始化
%--------------------------------------------------------------------------
%小图线段长度：34 156
%大图线段长度：29 128
%因此小图缩放比例是 小图 × 128/156 = 大图
%----------debug模拟输入参数
% close all;clear;clc;
% videoFileName = 'G:\tenet\Capture\201811940110.mp4';
% bigMapFolder = 'G:\tenet\Capture\map';

%----------文件信息
matFileName = strrep(videoFileName,'.mp4','.mat');
startFrame = 1;

%----------截图位置
%horizon =  [98  287];
%vertical = [811 1001];
startPointHV = [98 811];
endPointHV = [287 1001];
deltaHV = endPointHV - startPointHV - 1;
cropRect = [startPointHV deltaHV];
resizeFactor = 128/156;

%----------大小图匹配所用参数
trustThreshold = 0.9;
poolingFactor = 1;
boxStartPoint = [808 95];%小地图外边框的起止点，用来判断是不是在进行游戏。
boxEndPoint = [1005 291];
boxWidth = 2;%小地图边框为2像素宽度
boxLightnessThreshold = 160;
boxLightnessPixelNumberThreshold = 1564*trustThreshold;
runSpeed = 17;%在大地图上的最大跑动速度pixels/s
frameInvolvedFactor = 0.2;%有多少的帧将参与运算
lastPoint = [NaN NaN];
binarizeFactor = 0.55;
rotateDirectionNumber = 4;
recalibrationSecond = 2;%每隔多少秒有一次重校准
angleHalfTolerance = 20;%角度容差，用来增强旋转的冗余性
originalThetaRange = [-90 90];
clusterOffsetAngle = [0 45];%这是对应多重聚类的，为了防止89°和-89°被聚成两类。
colorArray = [26 46 70 102 146];%详尽图像匹配中使用，探测所有关键颜色的亮度范围
%----------准备大地图

bigMapFile = dir([bigMapFolder '\*.png']);
bigMapFileName = cell(length(bigMapFile),1);
bigMapImage = cell(length(bigMapFile));
for ii = 1:length(bigMapFile)
    bigMapFileName{ii} = [bigMapFile(ii).folder '\' bigMapFile(ii).name];
    bigMapImage{ii} = rgb2gray(imread(bigMapFileName{ii}));
end

%% ------------------------------------------------------------------------
%                               1.视频处理
%--------------------------------------------------------------------------
videoObject = VideoReader(videoFileName);
%---------------计算二级参数
%二级参数是根据基本参数和视频信息自动生成的，不用调整。
%----------帧检测相关参数
frameRate = round(videoObject.FrameRate);
frameStep = ceil(1/frameInvolvedFactor);%跳帧步长
oneFrameRange = 1/frameRate * runSpeed;
searchRange = ceil([oneFrameRange*frameStep oneFrameRange*frameStep]) * 2;%保守一点，×个2吧...
ifDetailDetect = 1;
recalibrationModNumber = mod(startFrame,ceil(frameRate*recalibrationSecond));
%----------游戏状态检测参数
boxMask = false(videoObject.Height,videoObject.Width);
%-----生成平行线
pointList = zeros(5,2);
for parallelLineIndex = 1:boxWidth
    parallelLineDeltaPixel = parallelLineIndex - 1;
    pointList(1,:) = boxStartPoint + parallelLineDeltaPixel;
    pointList(3,:) = boxEndPoint - parallelLineDeltaPixel;
    pointList(2,:) = [pointList(1,1) pointList(3,2)];
    pointList(4,:) = [pointList(3,1) pointList(1,2)];
    pointList(5,:) = pointList(1,:);
    for pointIndex = 1:4
        pointNumber = max( abs(pointList(pointIndex+1,:)-pointList(pointIndex,:)) ) + 1;
        linePointX = linspace(pointList(pointIndex,1),pointList(pointIndex+1,1),pointNumber);
        linePointY = linspace(pointList(pointIndex,2),pointList(pointIndex+1,2),pointNumber);
        linearIndex = sub2ind(size(boxMask),linePointX,linePointY);
        boxMask(linearIndex) = true;
    end
end
%imshow(rescale(boxMask));

%----------最终结果大矩阵
% 最终结果保存到一个矩阵videoOutcome中
% frameIndex bigMapIndex（楼层） 相对角度 X Y confidence
videoOutcome = zeros(videoObject.NumFrames,6);
lastNormalFrameIndex = NaN;

%----------清除多余变量
clearvars( ...
    "linearIndex","linePointX","linePointY","pointNumber","pointIndex","pointList","parallelLineDeltaPixel","parallelLineIndex",  ...
    "ii","bigMapFile","bigMapFolder"...
    );
%% ------------------------------------------------------------------------
%                               2.视频分析
%--------------------------------------------------------------------------
%---------------*帧检测*
frameIndex = startFrame;
while frameIndex <= videoObject.NumFrames
    try
        frame = read(videoObject,frameIndex);%imshow(frame);
        %----------游戏状态检测
        %如果没有小地图外框，那就说明没有正常游戏，这一帧标记-1，到下一帧。
        grayFrame = rgb2gray(frame);
        boxLightnessPixelNumber = sum(grayFrame(boxMask) > boxLightnessThreshold,'all');
        if boxLightnessPixelNumber < boxLightnessPixelNumberThreshold
            videoOutcome(frameIndex,:) = [frameIndex -1 -1 -1 -1 -1];
            fprintf("Frame = %d, Floor = %d, Position = %d %d, Confidence = %f, ifDetailDetect = %d, Not Playing.\n", ...
                videoOutcome(frameIndex,1), ...
                videoOutcome(frameIndex,2)-1, ...
                videoOutcome(frameIndex,4), ...
                videoOutcome(frameIndex,5), ...
                videoOutcome(frameIndex,6), ...
                ifDetailDetect ...
                );
            frameIndex = frameIndex + frameStep;
            continue;
        end
        %----------裁剪图像
        smallMapGray = imcrop(grayFrame,cropRect);

        %-----小地图缩放，使得和大地图截图的基本尺寸相同
        smallMapGray = imresize(smallMapGray,resizeFactor);
        % imshow(smallMapGray);

        %----------霍夫变换寻找直线
        smallMapBinary = imbinarize(smallMapGray,binarizeFactor);
        % imshow(smallMapBinary);
        lines = HoughTransformLineDetector(smallMapBinary);
        %-----清洗掉短线
        if sum([lines.lineLength] > 15) >= 5
            lines = lines([lines.lineLength] > 15);
        end
        %！！注意，这里的theta值代表着"旋转多少度能变回横线"！！
        % +27度代表逆时针转27度就变回横线了！
%         subplot(1,2,1);imshow(smallMapBinary);
%         subplot(1,2,2);imshow(smallMapBinary);hold on;
%         for  lineIndex = 1: length (lines)
%             xy = [lines(lineIndex).point1; lines(lineIndex).point2];
%             plot (xy(:,1),xy(:,2), 'LineWidth' ,2, 'Color' , 'green' );
% 
%             % Plot beginnings and ends of lines
%             plot (xy(1,1),xy(1,2), 'x' , 'LineWidth' ,2, 'Color' , 'yellow' );
%             plot (xy(2,1),xy(2,2), 'x' , 'LineWidth' ,2, 'Color' , 'red' );
%         end
%         hold off;

        %----------双重聚类
        %[-90,90)正常角度聚类，[-45,135)半角偏移聚类
        %multiclusterMatrix用来保存每次的聚类结果和聚类残差，
        % tempThetaKmeansID;
        % residual;
        % tempThetaList;
        % tempThetaKmeansID;
        multiclusterMatrix = cell(length(clusterOffsetAngle),4);
        for clusterIndex = 1:length(clusterOffsetAngle)
            %-----角度转换
            tempThetaList = [lines.theta]';
            thetaRange = originalThetaRange + clusterOffsetAngle(clusterIndex);%奇怪，这里为什么不能顺手全改变量名？
            tempThetaList(tempThetaList < thetaRange(1)) = tempThetaList(tempThetaList < thetaRange(1)) + 180;
            %-----直线聚类，聚出垂直和水平的两类（如果有两类的话）
            tempThetaKmeansID = kmeans(tempThetaList,2);
            %-----聚类残差
            totalNumber = length(tempThetaKmeansID);
            %方法1：residual = SSE / (n-2);nnd，为啥算不对！
            %妈的，忘了用刚改完的tempThetaList了...焯。
            %         SST = var(tempThetaList,1) * totalNumber;
            %         SSR = var([ ...
            %             repmat(mean(tempThetaList(tempThetaKmeansID == 1)),1,sum(tempThetaKmeansID == 1)) ...
            %             repmat(mean(tempThetaList(tempThetaKmeansID == 2)),1,sum(tempThetaKmeansID == 2)) ...
            %             ],1) * totalNumber;
            %         SSE = SST - SSR;
            %         residual = SSE / (totalNumber-2);
            %方法2：residual = SSE1 + SSE2 / (n-2);
            SSE1 = var(tempThetaList(tempThetaKmeansID == 1),1) * sum(tempThetaKmeansID == 1);
            SSE2 = var(tempThetaList(tempThetaKmeansID == 2),1) * sum(tempThetaKmeansID == 2);
            SSE = (SSE1 + SSE2);
            residual = SSE / (totalNumber-2);
            %-----写入结果
            multiclusterMatrix{clusterIndex,1} = tempThetaKmeansID;
            multiclusterMatrix{clusterIndex,2} = residual;
            multiclusterMatrix{clusterIndex,3} = tempThetaList;
            multiclusterMatrix{clusterIndex,4} = tempThetaKmeansID;
        end
        [~,minIndex] = min([multiclusterMatrix{:,2}]);
        thetaList = multiclusterMatrix{minIndex,3};
        thetaKmeansID = multiclusterMatrix{minIndex,4};

        if mean(thetaList(thetaKmeansID == 1)) - mean(thetaList(thetaKmeansID == 2)) >= 0
            positiveValue = 1;
        else
            positiveValue = 2;
        end
        negativeValue = 3-positiveValue;
        positiveIndex = (thetaKmeansID == positiveValue);
        negativeIndex = (thetaKmeansID == negativeValue);
        meanTheta(1) = sum(thetaList(positiveIndex) .* [lines(positiveIndex).lineLength]') / sum([lines(positiveIndex).lineLength]);
        meanTheta(2) = sum(thetaList(negativeIndex) .* [lines(negativeIndex).lineLength]') / sum([lines(negativeIndex).lineLength]);
        if (abs(meanTheta(1) - meanTheta(2)) < 90+angleHalfTolerance) && (abs(meanTheta(1) - meanTheta(2)) > 90-angleHalfTolerance)
            %---角度加权重新分配
            %这里的+90大小值之间应该就是差90度的，所以期望值上+90就够了。
            realMeanTheta = ...
                (meanTheta(1)*sum([lines(positiveIndex).lineLength]) ...
                + (meanTheta(2)+90)*sum([lines(negativeIndex).lineLength]))...
                / sum([lines.lineLength]);
        else
            %如果只有一类，那就直接所有求和
            %realMeanTheta = sum([lines(1:3).theta] .* [lines(1:3).lineLength]) / sum([lines(1:3).lineLength]);
            realMeanTheta = sum(thetaList .* [lines.lineLength]') /sum([lines.lineLength]);%莫名其妙会让坐标算到地下一层去...
        end

        %-----小图旋转，转出4个可能的方向
        rotatedImage = cell(rotateDirectionNumber,1);
        rotatedImageBlackMask = cell(rotateDirectionNumber,1);
        for rotateIndex = 1:rotateDirectionNumber
            tempRotateTheta = realMeanTheta + rotateIndex*90;
            tempImage = imrotate(smallMapGray,tempRotateTheta,'bicubic');
            %---太白的地方我们不算,这是为了删除LOGO和玩家锚
            tempImage(tempImage > 160) = 0;
            %---全黑的地方打上mask
            rotatedImageBlackMask{rotateIndex} = (tempImage == 0);
            rotatedImage{rotateIndex} = tempImage;
            %imshow(tempImage);pause();
        end

        %-----缩减搜索范围
        %跟上一个正常帧比较，层数和位移
        bigMapIndexRange = [1 length(bigMapFileName)];
        if ~isnan(lastNormalFrameIndex)
            lastNormalBigMapIndex = videoOutcome(lastNormalFrameIndex,2);
            bigMapIndexRange(1) = lastNormalBigMapIndex - 1;
            bigMapIndexRange(2) = lastNormalBigMapIndex + 1;
            %卡一下范围
            bigMapIndexRange(bigMapIndexRange<1) = 1;
            bigMapIndexRange(bigMapIndexRange>length(bigMapFileName)) = length(bigMapFileName);
        end

        %----------------核心部分：大小图匹配
        %有一个整体比较列表：totalMatchMatrix
        % 行数 = 6个大地图 × 4个旋转角度
        %bigMapIndex, rotateIndex, maxPointX, maxPointY, maxPointCredibility;
        totalMatchMatrix = zeros(length(bigMapFileName).*rotateDirectionNumber,5);
        lineIndex = 1;
        %----------开始检测
        if ifDetailDetect == 0
            %-----快速检测
            for bigMapIndex = bigMapIndexRange(1):bigMapIndexRange(2)
                tempBigMapImage = bigMapImage{bigMapIndex};
                for rotateIndex = 1:rotateDirectionNumber
                    [maxPointXY,~,maxPointCredibility] = FastImageCoordinateMatcher( ...
                        rotatedImage{rotateIndex}, ...
                        tempBigMapImage, ...
                        'smallImageZeroMask',rotatedImageBlackMask{rotateIndex}, ...
                        'poolingFactor',poolingFactor, ...
                        'lastPoint',lastPoint, ...
                        'searchRange',searchRange, ...
                        'binarizeFactor',binarizeFactor, ...
                        'ifShowProcess',false ...
                        );
                    totalMatchMatrix(lineIndex,:) = [ ...
                        bigMapIndex, ...
                        rotateIndex, ...
                        maxPointXY, ...
                        maxPointCredibility ...
                        ];
                    lineIndex = lineIndex + 1;
                end
            end
        elseif ifDetailDetect == 1
            %-----详细检测
            for bigMapIndex = bigMapIndexRange(1):bigMapIndexRange(2)
                tempBigMapImage = bigMapImage{bigMapIndex};
                for rotateIndex = 1:rotateDirectionNumber
                    [maxPointXY,~,maxPointCredibility] = ImageCoordinateMatcher( ...
                        rotatedImage{rotateIndex}, ...
                        tempBigMapImage, ...
                        'colorArray',colorArray, ...
                        'smallImageZeroMask',rotatedImageBlackMask{rotateIndex}, ...
                        'poolingFactor',poolingFactor, ...
                        'lastPoint',lastPoint, ...
                        'searchRange',searchRange, ...
                        'binarizeFactor',binarizeFactor, ...
                        'ifShowProcess',false ...
                        );
                    totalMatchMatrix(lineIndex,:) = [ ...
                        bigMapIndex, ...
                        rotateIndex, ...
                        maxPointXY, ...
                        maxPointCredibility ...
                        ];
                    lineIndex = lineIndex + 1;
                end
            end
        end
        %-----如果置信度太低，就不要了，默认90%，这样可以剔除开场动画
        %草，还是别了，我怕它算不出来。开场动画还是手动剔除吧...
        %获取和上一个正常值距离合理、楼层数合理的。太远的直接认为不可信。
        if ~isnan(lastNormalFrameIndex)
            deltaFrame = frameIndex - lastNormalFrameIndex;
            abnormalMatchMatrixIndex = sum( ...
                (totalMatchMatrix(:,3:4)-videoOutcome(lastNormalFrameIndex,4:5)) ...
                <= (ceil([oneFrameRange*deltaFrame oneFrameRange*deltaFrame])*2) ...
                ,2) ~= 2;
            totalMatchMatrix(abnormalMatchMatrixIndex,end) = -1;%!应该改成让这一行都是-1
        end

        [maxValue,maxConfidenceLine] = max(totalMatchMatrix(:,end),[],'all','linear');
        % frameIndex bigMapIndex（楼层） 相对角度 X Y confidence
        lastPoint = totalMatchMatrix(maxConfidenceLine,3:4);
        relativeAngle = -(realMeanTheta + totalMatchMatrix(maxConfidenceLine,2)*90);
        videoOutcome(frameIndex,1) = frameIndex;
        videoOutcome(frameIndex,2) = totalMatchMatrix(maxConfidenceLine,1);
        videoOutcome(frameIndex,3) = relativeAngle;
        videoOutcome(frameIndex,4:5) = lastPoint;
        videoOutcome(frameIndex,6) = maxValue;
        fprintf("Frame = %d, Floor = %d, Position = %d %d, Confidence = %f, ifDetailDetect = %d, Normal.\n", ...
            videoOutcome(frameIndex,1), ...
            videoOutcome(frameIndex,2)-1, ...
            videoOutcome(frameIndex,4), ...
            videoOutcome(frameIndex,5), ...
            videoOutcome(frameIndex,6), ...
            ifDetailDetect ...
            );

        %----------------重校准
        % 每到关键帧的时候会有重校准，或者可信度低的时候也有重校准。
        if mod(frameIndex+1-startFrame,ceil(frameRate*recalibrationSecond)) == recalibrationModNumber
            %---强制校准
            save(matFileName,'videoOutcome');
            lastPoint = [NaN NaN];
            lastNormalFrameIndex = NaN;
            frameIndex = frameIndex + frameStep;
            ifDetailDetect = 1;
        elseif maxValue<=trustThreshold
            %---低可信度重算
            %lastPoint = [NaN NaN];
            if ifDetailDetect == 0
                ifDetailDetect = 1;
                continue;
            else
                ifDetailDetect = 0;
                frameIndex = frameIndex + frameStep;
            end
        else
            %---正常
            lastNormalFrameIndex = frameIndex;
            frameIndex = frameIndex + frameStep;
            ifDetailDetect = 0;
        end
    %---------------BUG冗余
    catch
        if ifRecompulate == 0
            %如果没有重算过，那就再算一遍。
            ifRecompulate = ifRecompulate + 1;
        else
            videoOutcome(frameIndex,:) = [frameIndex -2 -2 -2 -2 -2];
            fprintf("Frame = %d, Floor = %d, Position = %d %d, Confidence = %f, ifDetailDetect = %d, Serious Error.\n", ...
                videoOutcome(frameIndex,1), ...
                videoOutcome(frameIndex,2)-1, ...
                videoOutcome(frameIndex,4), ...
                videoOutcome(frameIndex,5), ...
                videoOutcome(frameIndex,6), ...
                ifDetailDetect ...
                );
            frameIndex = frameIndex + frameStep;
            ifRecompulate = 0;
        end
        continue;
    end
end

%% ------------------------------------------------------------------------
%                               3.输出结果
%--------------------------------------------------------------------------
%----------保存同名文件
% 记录坐标、地图、统计性结果
% axesHandle = axes();
% imshow(tempBigMapImage,'Parent',axesHandle);hold on;
% plot(900,700,'Marker','*','MarkerFaceColor','r','MarkerSize',20,'Parent',axesHandle);
%
%
%
% plotXY = videoOutcome(:,4:5);
% plotX = plotXY(plotXY(:,1)>0,1);
% plotY = plotXY(plotXY(:,2)>0,2);
% plot(plotY,plotX,'Parent',axesHandle);
% xlim([1 size(tempBigMapImage,1)]);
% ylim([1 size(tempBigMapImage,2)]);

save(matFileName,'videoOutcome');
%----------生成动画，记录玩家跑到哪里了
end