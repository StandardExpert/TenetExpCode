function lines = HoughTransformLineDetector(image)
%lines = HoughTransformLineDetector(image)
% 霍夫变换找出二值化图像中的直线，有图形输出的源代码来自https://blog.csdn.net/kateyabc/article/details/79974622
% 官方霍夫变换算法说明：https://ww2.mathworks.cn/help/images/ref/hough.html#buwgokq-6
% 需要输入一个已经做过二值化的图片image。
% 返回值一个结构体，装着所有直线的：
% 起点point1
% 终点point2
% 角度[-90,90)
% 弦长rho
% 线长lineLength

%----------Find edges
image = edge(image);
%----------Create the Hough transform using the binary image.
[H,theta,rho] = hough(image);
%----------Find peaks in the Hough transform of the image.
peaks  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
%----------Find lines and plot them.
originLines = houghlines(image,theta,rho,peaks,'FillGap',5,'MinLength',10);

%----------Rearrange Output
%小心邪门的正负值！
for lineIndex = 1:length(originLines)
    %-----计算线长
    originLines(lineIndex).lineLength = norm(originLines(lineIndex).point1 - originLines(lineIndex).point2);
end
[~,lineIndexList] = sort([originLines.lineLength],'descend');
lines =  originLines(lineIndexList);

end