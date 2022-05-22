function [maxPointXY,maxPointLinearIndex,maxPointCredibility] = FastImageCoordinateMatcher(smallImage,bigImage,varargin)
% [maxPointXY,maxPointLinearIndex,maxPointCredibility] = FastImageCoordinateMatcher(smallImage,bigImage)
% [maxPointXY,maxPointLinearIndex,maxPointCredibility] = FastImageCoordinateMatcher( ...
%     smallImage, ...
%     bigImage, ...
%     'smallImageZeroMask',smallImageZeroMask, ...
%     'bigImageZeroMask',bigImageZeroMask, ...
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
for arginIndex = 1:length(varargin)
    if ischar(varargin{arginIndex})
        switch varargin{arginIndex}
            case 'smallImageZeroMask'
                smallImageZeroMask = varargin{arginIndex + 1};
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

%---------------大小图二值化
smallImage = imrotate(smallImage,180);
smallImageZeroMask = imrotate(smallImageZeroMask,180);
if gpuAvailable
    smallImageProcessed = gpuArray(rescale(imbinarize(smallImage,binarizeFactor),-1,1));
    bigImageProcessed = gpuArray(rescale(imbinarize(bigImage,binarizeFactor),-1,1));
else
    smallImageProcessed = rescale(imbinarize(smallImage,binarizeFactor),-1,1);
    bigImageProcessed = rescale(imbinarize(bigImage,binarizeFactor),-1,1);
end

%----------打上0的Mask
smallImageProcessed(smallImageZeroMask) = 0;
bigImageProcessed(bigImageZeroMask) = 0;

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
    convCore = zeros(size(smallImageProcessed,1),size(smallImageProcessed,2));
else
    convCore = gpuArray(zeros(size(smallImageProcessed,1),size(smallImageProcessed,2)));
end
convCore(chosenList) = smallImageProcessed(chosenList);

% montage({ ...
%     rescale(smallImage),...
%     rescale(smallImagePreProcessed),...
%     rescale(smallImageZeroMask),...
%     rescale(smallImageProcessed)...
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
%                               2.卷积探测
%--------------------------------------------------------------------------
%测试结果Part2 Time = 0.769761，原来是因为卷积核是CPU
%改卷积核Part2 Time = 0.172335
tic;
%-----二维卷积
%conv2(a,b,shape)，a是被卷积矩阵，b是卷积核
%'valid'，减量卷积。完全不补充外界，只在内部能卷积的部分卷。
%'same'，等量卷积。稍加补充，卷积核b的中心沿着a走，结果和a一样大。
%'full'，增量卷积。外围补0，一直补充到最小交集外界。shape默认是它。
% 我套死你猴子的，为啥卷积核非要转180度，为啥？？？？狗贼，老子还得手动转回来！
% 焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯焯！
% montage({ ...
%     rescale(bigImageProcessed), ...
%     rescale(smallImageProcessed) ...
%     });

convOutcome = conv2(bigImageProcessed,convCore,'valid') ./ validNumber;
%valid比same要快，快多少要看小图和大图的尺寸比。
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