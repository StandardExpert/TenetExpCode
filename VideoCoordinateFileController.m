function VideoCoordinateFileController()

%% ------------------------------------------------------------------------
%                               0.初始化
%--------------------------------------------------------------------------
mFilePath = which('VideoCoordinateFileController');
slashPosition = strfind(mFilePath,'\');
cd(mFilePath( 1: (slashPosition(end)-1) ));
clear;clc;close all;
%-----视频文件
rootDir = pwd;
videoFileFolder = [rootDir '\' 'Capture'];
videoFileNameStruct = dir([videoFileFolder '\*.mp4']);
%-----地图文件
bigMapFolder = [rootDir '\' 'Capture' '\' 'map'];

%-----结果输出
ifGenerateVideo = true;
%% ------------------------------------------------------------------------
%                               1.视频处理
%--------------------------------------------------------------------------
% for ii = 1:4
%     videoFileName = [videoFileFolder '\' videoFileNameStruct(ii).name];
%     VideoCoordinate(videoFileName,bigMapFolder);
%     VideoOutcomeStatistic(videoFileName,bigMapFolder,ifGenerateVideo);
% end

videoFileName = ['G:\tenet\demoVideo.mp4'];
%VideoCoordinate(videoFileName,bigMapFolder);
VideoOutcomeStatistic(videoFileName,bigMapFolder,ifGenerateVideo);
end