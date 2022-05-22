function [maxPointXY,maxPointLinearIndex,maxPointCredibility] = ImageCoordinateMatcher(smallImage,bigImage,varargin)
% [maxPointXY,maxPointLinearIndex,maxPointCredibility] = ImageCoordinateMatcher(smallImage,bigImage)
% [maxPointXY,~,maxPointCredibility] = ImageCoordinateMatcher( ...
%     rotatedImage{rotateIndex}, ...
%     tempBigMapImage, ...
%     'colorArray',colorArray, ...
%     'smallImageZeroMask',rotatedImageBlackMask{rotateIndex}, ...
%     'poolingFactor',poolingFactor, ...
%     'lastPoint',lastPoint, ...
%     'searchRange',searchRange, ...
%     'binarizeFactor',binarizeFactor, ...
%     'ifShowProcess',false ...
%     );
%这个函数非常的傻，只负责池化、卷积、匹配。但是也非常快速。
% 所以，请塞进来 灰！度！图！ 并且建议给出图片中的0域，就是不算在内的点的遮罩。
% smallImage            小图，是个灰度图。
% bigImage              大图，也是个灰度图。
% smallImageZeroMask    小图中不参与计算的点的遮罩标记。
% colorArray            要进行匹配的所有颜色
% bigImageZeroMask      大图中不参与计算的点的遮罩标记。
% poolingFactor         池化采样的因子，是一个0~100%的数，默认全采样。
% lastPoint             上次找出的点，如果有，就只在这个点的周围找，可以提高速度。
% searchRange           搜寻范围，是deltaX的半径和deltaY的半径。
%                       当lasktPoint为[NaN NaN]时，searchRange会变为默认全屏。
% binarizeFactor        二值化参数。不过只在FastImageCoordinateMatcher起作用。
% ifShowProcess         是否展示每一模块的运行时间。

%% ------------------------------------------------------------------------
%                                0.初始化
%--------------------------------------------------------------------------
%测试结果：Part0 Time = 0.002858
tic;
poolingFactor = 1;
lastPoint = [NaN NaN];
searchRange = [NaN NaN];
smallImageZeroMask = false(size(smallImage,1),size(smallImage,2));
bigImageZeroMask = false(size(bigImage,1),size(bigImage,2));
binarizeFactor = 0.55;
ifShowProcess = false;
colorTolarence = 5;
for arginIndex = 1:length(varargin)
    if ischar(varargin{arginIndex})
        switch varargin{arginIndex}
            case 'smallImageZeroMask'
                smallImageZeroMask = varargin{arginIndex + 1};
            case 'colorArray'
                colorArray = varargin{arginIndex + 1};
            case 'bigImageZeroMask'
                bigImageZeroMask = varargin{arginIndex + 1};
            case 'poolingFactor'
                poolingFactor = varargin{arginIndex + 1};
            case 'lastPoint'
                lastPoint = varargin{arginIndex + 1};
            case 'searchRange'
                searchRange = varargin{arginIndex + 1};
            case 'binarizeFactor'
                binarizeFactor = varargin{arginIndex + 1};
            case 'ifShowProcess'
                ifShowProcess = varargin{arginIndex + 1};
        end
    end
end
%-----判断是否可以调用显卡
gpuInformation = gpuDevice;
if isempty(strfind(gpuInformation.Name,'NVIDIA'))
    gpuAvailable = false;
else
    gpuAvailable = true;
end

if ifShowProcess
    fprintf("Part0 Time = %f\n",toc);
end

% colorTolarence = 5;
% ifShowProcess = true;
% gpuAvailable = true;
% smallImage = rotatedImage{rotateIndex};
% bigImage = tempBigMapImage;
% poolingFactor = 1;
% smallImageZeroMask = rotatedImageBlackMask{rotateIndex};
% bigImageZeroMask = false(size(bigImage,1),size(bigImage,2));
% binarizeFactor = 0.55;
% searchRange = [NaN NaN];
% lastPoint = [NaN NaN];
%% ------------------------------------------------------------------------
%                                1.预处理
%--------------------------------------------------------------------------
%测试结果：Part1 Time = 0.018397
tic;
%---------------大小图预处理
smallImage = imrotate(smallImage,180);
smallImageZeroMask = imrotate(smallImageZeroMask,180);

if gpuAvailable
    smallImageProcessed = gpuArray(double(smallImage)/255);
    bigImageProcessed = gpuArray(double(bigImage)/255);
    bigImageZeroMask = gpuArray(bigImageZeroMask);
    smallImageZeroMask = gpuArray(smallImageZeroMask);
    colorArray = gpuArray(colorArray);
    colorTolarence = gpuArray(colorTolarence);
else
    smallImageProcessed = double(smallImage)/255;
    bigImageProcessed = double(bigImage)/255;
end

%---------------大图根据上一个点截取
%注意！坐标默认是以XY输入的，HV本质是YX！
%注意！卷积核不能比基本图像要小！一旦小了的话卷积结果是NaN！
smallImageSize = size(smallImage);
%smallImageSizeHV = fliplr(smallImageSize);%这个参数暂时用不到，就不管了。
bigImageSize = size(bigImage);
bigImageSizeHV = fliplr(bigImageSize);
deltaHV = [0 0];
basicPoint = [1 1];
if ~isnan(lastPoint)
    %----------起点
    startPointHV = fliplr(lastPoint-searchRange-ceil(smallImageSize/2));
    %-----防止截图出界，卡一下小值下限
    if sum(startPointHV<1)
        deltaHV(startPointHV<1) = deltaHV(startPointHV<1) + basicPoint(startPointHV<1) - startPointHV(startPointHV<1);
    end
    
    %----------终点
    endPointHV = fliplr(lastPoint+searchRange+ceil(smallImageSize/2));
    %-----防止截图出界，卡一下大值上限
    if sum(endPointHV>bigImageSizeHV)
        deltaHV(endPointHV>bigImageSizeHV) = deltaHV(endPointHV>bigImageSizeHV) + bigImageSizeHV(endPointHV>bigImageSizeHV) - startPointHV(startPointHV<1);
    end
    
    %----------截图
    startPointHV = startPointHV + deltaHV;
    endPointHV = endPointHV + deltaHV;
    cropRect = [startPointHV endPointHV-startPointHV-1];
    bigImageProcessed = imcrop(bigImageProcessed,cropRect);
else
    startPointHV = basicPoint;
end


%----------池化
validLinearIndex = find(smallImageProcessed ~= 0);
validNumber = length(validLinearIndex);
randList = randperm(validNumber);
cutPoint = floor(poolingFactor.*validNumber);
chosenList = validLinearIndex(randList(1:cutPoint));

%-----提取
if gpuAvailable
    convCore = gpuArray(zeros(size(smallImageProcessed,1),size(smallImageProcessed,2)));
else
    convCore = zeros(size(smallImageProcessed,1),size(smallImageProcessed,2));
end
convCore(chosenList) = smallImageProcessed(chosenList);

% montage({ ...
%     rescale(smallImage), ...
%     rescale(smallImageZeroMask), ...
%     rescale(smallImageProcessed), ...
%     rescale(convCore) ...
%     });
% imwrite(rescale(smallImageProcessed),'smallImageProcessed.png');
% montage({ ...
%     rescale(bigImage), ...
%     rescale(bigImageProcessed) ...
%     });
% imwrite(rescale(bigImageProcessed),'bigImageProcessed.png');
if ifShowProcess
    fprintf("Part1 Time = %f\n",toc);
end
%% ------------------------------------------------------------------------
%                         2.多色块最优位置探测
%--------------------------------------------------------------------------
%测试结果Part2 Time = 2.661595
%更换GPU Part2 Time = 
tic;
%bigImageProcessed,convCore
for colorIndex = 1:length(colorArray)
    %tic;
    %----------取颜色范围
    tempColorRange = [colorArray(colorIndex)-colorTolarence colorArray(colorIndex)+colorTolarence] / 255;
    %fprintf("取色 Time = %f\n",toc);
    %----------卷积参数预处理
    tempBigImageProcessed = bigImageProcessed>=tempColorRange(1) & bigImageProcessed<=tempColorRange(2);
    tempBigImageProcessed = rescale(tempBigImageProcessed,-1,1);
    tempConvCore = convCore>=tempColorRange(1) & convCore<=tempColorRange(2);
    tempConvCore = rescale(tempConvCore,-1,1);
    %fprintf("预处理 Time = %f\n",toc);
    %----------打上0的Mask
    tempBigImageProcessed(bigImageZeroMask) = 0;
    tempConvCore(smallImageZeroMask) = 0;
    %fprintf("Mask Time = %f\n",toc);
    %----------卷他丫的
    %imshow(rescale(tempBigImageProcessed));
    %imshow(rescale(tempConvCore));
    tempConvOutcome = conv2(tempBigImageProcessed,tempConvCore,'valid') ./ validNumber;
    %fprintf("卷 Time = %f\n",toc);
    %----------多层求和
    if colorIndex == 1
        convOutcome = tempConvOutcome;
    else
        convOutcome = convOutcome + tempConvOutcome;
    end
    %fprintf("求和 Time = %f\n",toc);
%     montage({ ...
%         rescale(convOutcome), ...
%         rescale(tempConvOutcome) ...
%         });
%     pause();
end
convOutcome = convOutcome / length(colorArray);
%imshow(rescale(convOutcome));
[maxValue,maxIndex] = max(convOutcome,[],'all','linear');
[maxRow,maxCow] = ind2sub(size(convOutcome),maxIndex);

if ifShowProcess
    fprintf("Part2 Time = %f\n",toc);
end
%% ------------------------------------------------------------------------
%                               3.结果输出
%--------------------------------------------------------------------------
tic;
if gpuAvailable
    maxPointLinearIndex = gather(maxIndex);
    maxPointXY = gather([maxRow,maxCow]);
    maxPointCredibility = gather(maxValue);
else
    maxPointLinearIndex = maxIndex;
    maxPointXY = [maxRow,maxCow];
    maxPointCredibility = maxValue;
end
%！！这里还有问题！！应该改成截好的大图的cropRect
maxPointXY = maxPointXY + ceil(smallImageSize/2) - 1 + fliplr(startPointHV) - 1;

if ifShowProcess
    fprintf("Part3 Time = %f\n",toc);
end

end