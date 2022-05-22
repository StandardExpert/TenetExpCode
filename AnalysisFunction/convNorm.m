function convOutcome = convNorm(bigImageProcessed,convCore)
%convOutcome = convNorm(bigImageProcessed,convCore)
%卷norm，顾名思义，用类似卷积的方式判断两个图的亮度欧式距离。要求图片是double!
%目前仅支持valid模式
%----------计算valid矩阵
bigImageSize = size(bigImageProcessed);
convCoreSize = size(convCore);
xDeltaLength = bigImageSize(1) - convCoreSize(1) + 1;
yDeltaLength = bigImageSize(2) - convCoreSize(2) + 1;
convOutcome = nan(xDeltaLength,yDeltaLength);
for xx = 1:xDeltaLength
    for yy = 1:yDeltaLength
        bigImageCrop = bigImageProcessed(xx:xx+convCoreSize(1)-1,yy:yy+convCoreSize(2)-1);
        convOutcome(xx,yy) = sqrt(sum((convCore-bigImageCrop).^2,"all"));
    end
end

end