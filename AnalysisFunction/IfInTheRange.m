function ifInTheRange = IfInTheRange(pointList,range,varargin)
%ifInTheRangeList = IfInTheRange(pointList,range,varargin)
%ifInTheRange = IfInTheRange(startPointList,range,'trustThreshold',trustThreshold);
% 判断列表中的所有点是否在区域内。
% pointList：点的列表，每行是一个[x y];
% range：范围，是[startPointX startPointY endPointX endPoinY];
% trustThreshold：可选输入参数。一旦输入，则认为判断是不是列表中的大部分都在，只返回一个logical值。

%% ------------------------------------------------------------------------
%                                0.初始化
%--------------------------------------------------------------------------
tic;
trustThreshold = NaN;
for arginIndex = 1:length(varargin)
    if ischar(varargin{arginIndex})
        switch varargin{arginIndex}
            case 'trustThreshold'
                trustThreshold = varargin{arginIndex + 1};
        end
    end
end

%% ------------------------------------------------------------------------
%                                 1.判断
%--------------------------------------------------------------------------
xJudgeList = (pointList(:,1) >= range(1)) & (pointList(:,1) <= range(3));
yJudgeList = (pointList(:,2) >= range(2)) & (pointList(:,2) <= range(4));
ifInTheRangeList = (xJudgeList+yJudgeList == 2);

%% ------------------------------------------------------------------------
%                                 2.输出
%--------------------------------------------------------------------------
if isnan(trustThreshold)
    ifInTheRange = ifInTheRangeList;
else
    ifInTheRange = (sum(ifInTheRangeList) >= trustThreshold*size(pointList,1));
end

end