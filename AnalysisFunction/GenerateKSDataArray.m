function KSData = GenerateKSDataArray(originalData)
%将只有一行或者一列的数据编程两列的数据KS检验需要的数据
%输出的KSData第一列是X，第二列是Y。X其实就是序号


dataLength = length(originalData);
xData = 1:dataLength;xData = xData';
yData = originalData;
if size(yData,2) == dataLength
    yData = yData';
end
KSData = [xData,yData];
end
