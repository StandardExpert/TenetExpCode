clear;clc;
dataMatrix1 = [
    1.1900    1.6500    2.3700    2.9600    3.4700    3.9500;
    0.8600    1.2600    1.8300    2.5400    3.0800    3.5700;
    1.0300    1.7200    2.3500    3.0100    3.5300    4.1200;
    1.6400    2.4900    3.5700    4.4500    5.0300    5.9000;
    0.9600    1.4400    2.0000    2.5700    3.1500    3.6500;
    1.6400    2.0900    2.6200    3.2000    3.9800    4.4500;
    1.2300    1.7900    2.3200    2.8200    3.3300    3.7900;
    0.9500    1.6100    2.4100    3.0000    3.5300    4.0500;
    1.6500    2.9100    4.5100    5.6900    6.9800    7.6600;
    ];
dataMatrix2 = [
    2.2300    2.6900    3.9100    4.8200    6.2900    7.1100;
    0.7900    1.2000    1.7400    2.6800    3.2900    3.7500;
    0.7400    2.0200    2.5900    3.4300    4.2500    4.6700;
    2.9100    3.5300    7.2700    8.9700    9.6600   10.1700;
    1.2200    1.9200    3.0600    3.7300    4.2300    4.8300;
    3.5200    4.4200    6.8100    7.6100    8.4700    8.9100;
    1.0800    1.8100    2.6500    4.1700    5.0600    5.4600;
    0.8500    1.5800    2.2800    3.3400    3.7800    4.2100;
    2.6900    6.3200   10.1400   11.6600   14.6100   15.5100;
    ];

deltaMatrix = repmat([1:6]*0.4,9,1);
dataMatrix2 = dataMatrix2 - deltaMatrix;

array1 = zeros(numel(dataMatrix1),2);
array1(:,1) = sort(repmat([1:6]',9,1));
array1(:,2) = dataMatrix1(:);

array2 = zeros(numel(dataMatrix2),2);
array2(:,1) = sort(repmat([1:6]',9,1));
array2(:,2) = dataMatrix2(:);

arrayDelta = zeros(numel(dataMatrix2),2);
arrayDelta(:,1) = sort(repmat([1:6]',9,1));
arrayDelta(:,2) = dataMatrix1(:)-dataMatrix2(:);

arrayDelta0 = zeros(numel(dataMatrix2),2);
arrayDelta0(:,1) = sort(repmat([1:6]',9,1));

ifDrawPlot = true;
saveOutcomeFolder = 'G:\tenet\Capture';
fitParameterArray = [1000, 0 ,100];
MonteCarloMethodRepeatTime = 1000;
sig = LinearClassKSGoodnessFitTest( ...
    arrayDelta, ...
    arrayDelta0, ...
    ifDrawPlot, ...
    saveOutcomeFolder ...
    );






