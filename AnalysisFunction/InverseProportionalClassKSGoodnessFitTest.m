function sig = InverseProportionalClassKSGoodnessFitTest(array1,array2,fitParameterArray,MonteCarloMethodRepeatTime,ifDrawPlot,saveOutcomeFolder,saveOutcomeIndex)
%反比例 类K-S 拟合优度检验
% 输入两组数据，每一组的矩阵必须为2列，要求第一列是X，第二列是Y，
% 且数据标准化放缩到了[100,1000]
% 返回值是显著性sig
%% ------------------------------------------------------------------------
%                                0.初始化
%--------------------------------------------------------------------------
%---------------调试
% array1 = allForwardHesitateTimeArray;
% array2 = allBackwardHesitateTimeArray;
% saveOutcomeFolder = 'G:\tenet\Capture';
% ifDrawPlot = true;
% array1 = Group1Matrix;
% array2 = Group2Matrix;
% saveOutcomeFolder = 'G:\tenet\Data\Rodent';
% ifDrawPlot = true;
% array1 = tempGroup1Matrix;
% array2 = tempGroup2Matrix;
% saveOutcomeFolder = 'G:\tenet\Data\Rodent';
% ifDrawPlot = true;
%---------------生成基本量
%MonteCarloMethodRepeatTime = 1000;
alpha = 0.05;

xList1 = array1(:,1);
yList1 = array1(:,2);
xList2 = array2(:,1);
yList2 = array2(:,2);
xList0 = [xList1;xList2];
yList0 = [yList1;yList2];

[xList1,xList1SortIndex] = sort(xList1);
yList1 = yList1(xList1SortIndex);
xList1Range = [min(xList1):1:max(xList1)]';
xList1Number = xList1Range(end) - xList1Range(1) + 1;

[xList2,xList2SortIndex] = sort(xList2);
yList2 = yList2(xList2SortIndex);
xList2Range = [min(xList2):1:max(xList2)]';
xList2Number = xList2Range(end) - xList2Range(1) + 1;
%% ------------------------------------------------------------------------
%                                 1.拟合
%--------------------------------------------------------------------------
functionAnalytic=fittype('a/(x+b) + c','independent','x','coefficients',{'a','b','c'}); %fittype是自定义拟合函数
fun1 = fit(xList1,yList1,functionAnalytic,...
    'Startpoint', fitParameterArray,...
    'Lower', [0 -Inf -Inf], ...
    'Upper', [Inf 1 Inf] ...
    ); %根据自定义拟合函数f来拟合数据x，y
fun2 = fit(xList2,yList2,functionAnalytic,...
    'Startpoint', fitParameterArray,...
    'Lower', [0 -Inf -Inf], ...
    'Upper', [Inf 1 Inf] ...
    );
fun0 = fit(xList0,yList0,functionAnalytic,...
    'Startpoint', fitParameterArray,...
    'Lower', [0 -Inf -Inf], ...
    'Upper', [Inf 1 Inf] ...
    );

%% ------------------------------------------------------------------------
%                               2.蒙特卡洛
%--------------------------------------------------------------------------
%---------------获取拟合标准差
estimatedYList1 = fun1(xList1Range);
estimatedYList2 = fun2(xList2Range);

deltaY1List = zeros(length(yList1),1);
for lineIndex = 1:length(yList1)
    deltaY1List(lineIndex) = yList1(lineIndex) - estimatedYList1(xList1(lineIndex));
    %disp(deltaY1List(lineIndex));pause();
end
%plot(deltaY1List);

deltaY2List = zeros(length(yList2),1);
for lineIndex = 1:length(yList2)
    deltaY2List(lineIndex) = yList2(lineIndex) - estimatedYList2(xList2(lineIndex));
    %disp(deltaY2List(lineIndex));pause();
end
%plot(deltaY2List);
%----------获得本次实验的D
tempXX = [1:1:max([xList1Number,xList2Number])];
deltaD = fun1(tempXX) - fun2(tempXX);
basicD = max(deltaD);

totalSTD = std([deltaY1List; deltaY2List]);

%---------------Bootstrapping
totalDArray = zeros(MonteCarloMethodRepeatTime,1);
tic;
for ii = 1:MonteCarloMethodRepeatTime
    %----------Group1
    X1Bootstrapping = xList1Range;
    E1Bootstrapping = normrnd(0,totalSTD,xList1Number,1);
    Y1Bootstrapping = fun0(xList1Range) + E1Bootstrapping;
    tempFun1 = fit(X1Bootstrapping,Y1Bootstrapping,functionAnalytic,...
        'Startpoint', fitParameterArray,...
        'Lower', [0 -Inf -Inf], ...
        'Upper', [Inf 1 Inf] ...
        );
    %----------Group2
    X2Bootstrapping = xList2Range;
    E2Bootstrapping = normrnd(0,totalSTD,xList2Number,1);
    Y2Bootstrapping = fun0(xList2Range) + E2Bootstrapping;
    tempFun2 = fit(X2Bootstrapping,Y2Bootstrapping,functionAnalytic,...
        'Startpoint', fitParameterArray,...
        'Lower', [0 -Inf -Inf], ...
        'Upper', [Inf 1 Inf] ...
        );
    %----------获得D
    deltaD = tempFun1(tempXX) - tempFun2(tempXX);
    totalDArray(ii) = max(deltaD);

    t = toc;
    fprintf("Boostrapping is running at %d %f. Remain time %fs.\n",ii,totalDArray(ii),(MonteCarloMethodRepeatTime-ii)/ii*t);
end
%---------------Histogram
totalDArray = sort(totalDArray);

%[counts,centers] = hist(totalDArray);
sig = 1-(find(basicD > totalDArray,1,'last') / length(totalDArray));
%% ------------------------------------------------------------------------
%                                end.画图
%--------------------------------------------------------------------------
if ifDrawPlot
    %---------------准备Figure
    figureHandle = figure(1);
    set(figureHandle,'Color','w','menubar','none','toolbar','none','InvertHardCopy','off');
    %---------------准备数据
    xx=0:0.1:max([xList1;xList2]);
    y1=fun1(xx);
    y2=fun2(xx);
    y0=fun0(xx);
    %----------第一组
    plot(xList1,yList1, ...
        "Marker",'.', ...
        "MarkerSize",15,...
        "LineStyle","none",...
        "MarkerEdgeColor",[0, 0.69, 0.94]...
        );
    hold on;
    plot(xx,y1, ...
        "LineStyle",'-', ...
        "Color",[0, 0.69, 0.94]...
        );
    %---------第二组
    plot(xList2,yList2, ...
        "Marker",'.', ...
        "MarkerSize",15,...
        "LineStyle","none",...
        "MarkerEdgeColor",[0, 0.44, 0.75]...
        );
    plot(xx,y2, ...
        "LineStyle",'-', ...
        "Color",[0, 0.44, 0.75]...
        );
    %---------H0
    plot(xx,y0, ...
        "LineStyle",'--', ...
        "Color",[1, 0, 0]...
        );
    ylim([0,max(yList0)*1.2]);
    xlim([0,max(xList0)+1]);
    legend({'','Group 1','','Group 2','Group H0'});
    xlabel('Training times');
    ylabel('Normalized frame count');
    %----------Save
    fileLastName = sprintf('\\ProportionalClassKSGoodnessFitTest%d',saveOutcomeIndex);
    pngFileName = [saveOutcomeFolder fileLastName];
    print(pngFileName,'-dpng','-r600');
    close;
    %---------------直方图
    figureHandle = figure(2);
    set(figureHandle,'Color','w','menubar','none','toolbar','none','InvertHardCopy','off');
    axesHandle = axes();
    histogram(axesHandle,totalDArray);
    alphaX = totalDArray(round((1-alpha)*length(totalDArray)));
    line([alphaX,alphaX],[0,axesHandle.YLim(2)],"Color",[0,0,0],"LineStyle",'--');
    line([basicD,basicD],[0,axesHandle.YLim(2)],"Color",[1,0,0]);
    legend({'','α = 0.05','Sig. of the experimental data'});
    xlabel('D value');
    ylabel('Histogram count');
    %----------Save
    fileLastName = sprintf('\\ProportionalClassKSGoodnessFitTest_Sig%d',saveOutcomeIndex);
    pngFileName = [saveOutcomeFolder fileLastName];
    print(pngFileName,'-dpng','-r600');
    close;
end




end
