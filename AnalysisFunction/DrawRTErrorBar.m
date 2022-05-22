function DrawRTErrorBar(saveOutcomeFolder,plotName,thisGeometryParticipantMeanData)
%thisGeometryParticipantMeanData = allGeometryParticipantMeanData(participantIndex,:);
% DrawRTErrorBar(tempSaveOutcomeFolder,plotName,allGeometryParticipantMeanData(participantIndex,:));
% saveOutcomeFolder = tempSaveOutcomeFolder;
% plotName = plotName;
% thisGeometryParticipantMeanData = allGeometryParticipantMeanData(participantIndex,:);
%----------trial正确率，每一位的正确率，RT，-RT0，deltaRT 5个图(如果没有最后两列，就不用画。)
warning('off');

%-----基本参数
participantIndex = 1;
blueColor = [0,0.45,0.74];
redColor = [1.00,0.19,0.13];
yellowColor = [0.93,0.69,0.13];
barWidth = 0.4;
subplotRowNumber = 3;
subplotColumeNumber = 5;
voidRow = 1;

%-----打开Figure
%,'menubar','none','toolbar','none'
figureHandle = figure();
set(figureHandle,'units','normalized','position',[0.1 0.1 0.8 0.4]','Color','w','menubar','none','toolbar','none','InvertHardCopy','off');
%titleHandle = text(-11.84,27.81,plotName, 'HorizontalAlignment','center','FontSize',20);
%set(figureHandle,'units','normalized','position',[0.1 0.1 0.8 0.4]','Color','w','InvertHardCopy','off');
%suptitleHandle = suptitle(plotName);
%set(suptitleHandle,'Position',[0.5,-0.18,0]);

%-----生成子图handle
correctRateHandle = subplot(subplotRowNumber,subplotColumeNumber,voidRow*subplotColumeNumber + [1 1+subplotColumeNumber]);
sequenceCorrectRateHandle = subplot(subplotRowNumber,subplotColumeNumber,voidRow*subplotColumeNumber + [2 2+subplotColumeNumber]);
RTHandle = subplot(subplotRowNumber,subplotColumeNumber,voidRow*subplotColumeNumber + [3 3+subplotColumeNumber]);
RT0Handle = subplot(subplotRowNumber,subplotColumeNumber,voidRow*subplotColumeNumber + [4 4+subplotColumeNumber]);
if length(thisGeometryParticipantMeanData) > 14
    deltaHandle = subplot(subplotRowNumber,subplotColumeNumber,voidRow*subplotColumeNumber + [5 5+subplotColumeNumber]);
end

%-----按照顺反两类画图
for trialType = 1:2
    %保存这位被试的均值,1 2是总Trial的正确率,3 4 是每一位的正确率，5 6是RT，7 8是STDRT, 9 10是RT0，11 12是STDRT0，
    %13 14是deltaRT，15 16是allSTDDeltaRTArray
    
    if trialType == 1
        plotColor = blueColor;
        deltaX = -0.2;
    elseif trialType == 2
        plotColor = redColor;
        deltaX = 0.2;
    end
    
    meanTrialCorrectRate = thisGeometryParticipantMeanData{participantIndex,0*2 + trialType};
    meanCorrectRate = thisGeometryParticipantMeanData{participantIndex,1*2 + trialType};
    allMeanRTArray = thisGeometryParticipantMeanData{participantIndex,2*2 + trialType};
    allSTDRTArray = thisGeometryParticipantMeanData{participantIndex,3*2 + trialType};
    allMeanRT0Array = thisGeometryParticipantMeanData{participantIndex,4*2 + trialType};
    allSTDRT0Array = thisGeometryParticipantMeanData{participantIndex,5*2 + trialType};
    if length(thisGeometryParticipantMeanData) > 14
        allMeanDeltaRTArray = thisGeometryParticipantMeanData{participantIndex,6*2 + trialType};
        allSTDDeltaRTArray = thisGeometryParticipantMeanData{participantIndex,7*2 + trialType};
    end
    
    %-----trial正确率
    subplot(subplotRowNumber,subplotColumeNumber,voidRow*subplotColumeNumber + [1 1+subplotColumeNumber]);
    barX = [1:length(meanTrialCorrectRate)] + 3*deltaX;
    bar(correctRateHandle,barX,meanTrialCorrectRate*100,'FaceColor',plotColor,'EdgeColor','none','BarWidth',2*barWidth);
    xlabel('Recall direction');
    ylabel('Correct rate(%)');
    set(gca,'xtick',[],'xticklabel',[]);
    %set(gca,'xtick',[1:length(meanTrialCorrectRate)]);
    ylim([0,100]);
    subtitle('Correct rate');
    legend('Forward','Backward','Position',[0.592320963107049,0.768871256496619,0.077962240452568,0.087094909173471]);
    hold on;
    
    %-----每个位置的正确率
    subplot(subplotRowNumber,subplotColumeNumber,voidRow*subplotColumeNumber + [2 2+subplotColumeNumber]);
    barX = [1:length(meanCorrectRate)] + deltaX;
    bar(sequenceCorrectRateHandle,barX,meanCorrectRate*100,'FaceColor',plotColor,'EdgeColor','none','BarWidth',barWidth);
    xlabel('Sequence index');
    ylabel('Correct rate(%)');
    set(gca,'xtick',[1:length(meanCorrectRate)]);
    ylim([0,100]);
    subtitle('Sequence correct rate');
    hold on;
    
    %-----RT
    subplot(subplotRowNumber,subplotColumeNumber,voidRow*subplotColumeNumber + [3 3+subplotColumeNumber]);
    errorbar(RTHandle,allMeanRTArray,allSTDRTArray,'Marker','.','MarkerSize',20,'Color',plotColor);
    xlabel('Sequence index');
    ylabel('Reaction time(s)');
    xlim([0,length(allMeanRTArray)+1]);
    ylim([0,20]);
    set(gca,'xtick',[1:length(allMeanRTArray)]);
    subtitle('RT');
    hold on;
    
    %-----RT0
    subplot(subplotRowNumber,subplotColumeNumber,voidRow*subplotColumeNumber + [4 4+subplotColumeNumber]);
    errorbar(RT0Handle,allMeanRT0Array,allSTDRT0Array,'Marker','.','MarkerSize',20,'Color',plotColor);
    xlabel('Sequence index');
    ylabel('Reaction time(s)');
    xlim([0,length(allMeanRT0Array)+1]);
    ylim([0,20]);
    set(gca,'xtick',[1:length(allMeanRT0Array)]);
    if length(thisGeometryParticipantMeanData) > 14
        subtitle('RT without RT0');
    else
        subtitle('RT0');
    end
    hold on;
    
    %-----delta
    if length(thisGeometryParticipantMeanData) > 14
        subplot(subplotRowNumber,subplotColumeNumber,voidRow*subplotColumeNumber + [5 5+subplotColumeNumber]);
        errorbar(deltaHandle,allMeanDeltaRTArray,allSTDDeltaRTArray,'Marker','.','MarkerSize',20,'Color',plotColor);
        xlabel('Interval index ');
        ylabel('Reaction time(s)');
        xlim([0,length(allMeanDeltaRTArray)+1]);
        ylim([0,20]);
        set(gca,'xtick',[1:length(allMeanDeltaRTArray)]);
        subtitle('ΔRT');
        hold on;
    end
end
pngFileName = [saveOutcomeFolder '\' plotName];
print(pngFileName,'-dpng','-r600');
close;
end