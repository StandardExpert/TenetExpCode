function TenetScale()
% Author 李博华
% Time 2022/1/2 15:44

%--------------------------------------------------------------------------
%                      0. Rearrange the enviorment
%--------------------------------------------------------------------------
sca;clear;clc;
tic;

disp('0. Rearrange the enviorment accomplished!');
%--------------------------------------------------------------------------
%                       1. Get subject Information
%--------------------------------------------------------------------------
title = '被试信息';
prompt = {'被试学号:' }; %description of fields
defaults = {''};% you can put in default responses
answer = inputdlg(prompt, title, 1.2, defaults); %opens dialog
participantNumber = answer{1};
testdate =replace(datestr(datetime),':','-');

stimulusShowTime = 1;
stimulusVoidTime = 0.3;
rhythmSpeed = 0.5;% 1 beat is 500ms

disp('1. Get subject Information accomplished!');
%--------------------------------------------------------------------------
%                         2.  stimulus array
%--------------------------------------------------------------------------
%---------------要求：随机7个刺激，5个训练+40个测试
trainNumber = 5;
testNumber = 20;
itemNumber = 5;
sequenceLength = 5;
% participantNumber = '201811061199';
StimulusGeneratorScale(participantNumber,trainNumber,testNumber,itemNumber,sequenceLength);
load([participantNumber 'StimulusScale.mat'],'stimulusCell');

%--------------被试反应：
%前6列就是刺激序列，7列是按键顺序，8列是反应时（从trial指导语就开始了）
totalAnswerArray = stimulusCell;

disp('2. Get stimulus array accomplished!');
%--------------------------------------------------------------------------
%                       3. Set up PTB enviorment
%--------------------------------------------------------------------------
%---------------Sound
InitializePsychSound();
PsychPortAudio('Close');
PsychPortAudio('DeleteBuffer');
freq = 48000;%实验室电脑屏幕声音是这样的
latbias = (64/freq);%硬件延迟
pahandle = PsychPortAudio('Open', [], [], 2, freq);%打开声音设备。
% PsychPortAudio('FillBuffer', pahandle, soundWave);
% PsychPortAudio('Start', pahandle, 1, 0);

%---------------Image
waitframes = 0;
%Screen('Preference', 'SkipSyncTests', 0); % skip syncTest
ScrNum = min(Screen('Screens')); % Choose the internal screen, but PTB is very bad for Intel core graphics card support. If you formally experiment, you will choose an external screen, max.
black = BlackIndex(ScrNum);
screenSize = [0 0 1920 1081];
[windowPtr, rect]=Screen('OpenWindow',min(ScrNum), [128 128 128], screenSize);
[centerX, centerY] =  RectCenter(rect);  % coordinates of the window center
ifi = Screen('GetFlipInterval', windowPtr);  % second per frame, an estimate of the monitor flip interval
Screen('FillRect', windowPtr, 0);
vbl = Screen('Flip', windowPtr);
Screen('BlendFunction', windowPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Set the blend funciton for the screen
%Priority(MaxPriority(windowPtr));% If the program is really unable to run, then change the permissions.
ListenChar(2); % makes it so characters typed don't show up in the command window
HideCursor(); % hides the cursor


%---------------Keyboard
KbName('UnifyKeyNames'); %used for cross-platform compatibility of keynaming

% defining keys for response
startKey = KbName('space');
quitKey = KbName('escape');
keyIndex = KbName({'f','j'}); % LeftArrow(f,1) for visual response;RightArrow(j,2) for auditory response. Because right handed.

disp('3. Set up PTB enviorment accomplished!');
%--------------------------------------------------------------------------
%                  4. Stimulate material generation
%--------------------------------------------------------------------------
% 以国际标准音 A-la-440HZ为准，其他音均为la的2的1/12次方倍变化得到。
% C - do -  261.6HZ；D - re -  293.6HZ；
% E - mi -  329.6HZ；F - fa -  349.2HZ；
% G - sol- 392HZ；A - la -  440HZ；
% B - si -  493.8HZ。

%---------------Sound
samplingRate = freq;
perDuringTime = 1/samplingRate;
acousticFrequency = [261.6, 293.6, 329.6, 349.2, 392, 440, 493.8];
durationOfTheNote = 0.500;% equal to 500 milliseconds
timeScale = [0 : perDuringTime : durationOfTheNote];
volume = 0.3;%音量控制一下

%加入0.005秒的修饰，淡入、淡出，防止爆破音
modifyModulusIn = 1/(0.005*44100).*(0:0.005*44100);
modifyModulusOut = -modifyModulusIn+1;
modifyModulusOne = ones(1,length(timeScale) - length(modifyModulusIn) - length(modifyModulusOut));
modifyModulus = [modifyModulusIn modifyModulusOne modifyModulusOut];

for ii = 1:7
    soundWaveY = sin(2 * pi * timeScale * acousticFrequency(ii)).*modifyModulus * volume;
    soundWave{ii} = [soundWaveY; soundWaveY];%因为喇叭是双声道，所以读取双声道。
end
%---------------Image
rootDir = pwd; % get the path informatoin of current work directory
cd([rootDir '\ScaleStim']);

%----------load welcome words
welMatrixTraining = imread('welcomeTraining.jpg');
welTextureTraining = Screen('MakeTexture', windowPtr, welMatrixTraining);
welMatrixActual = imread('welcomeActual.jpg');
welTextureActual = Screen('MakeTexture', windowPtr, welMatrixActual);
welMatrixForward = imread('forward.jpg');
welTextureForward = Screen('MakeTexture', windowPtr, welMatrixForward);
welMatrixBackward = imread('backward.jpg');
welTextureBackward = Screen('MakeTexture', windowPtr, welMatrixBackward);
judgementmatrix = imread('judgement.jpg');
judgementTexture = Screen('MakeTexture', windowPtr, judgementmatrix);
cd(rootDir);

%----------generat other curtain
grayCurtain = im2uint8( ones(1080,1920,3) * 0.5);
grayCurtainTexture = Screen('MakeTexture', windowPtr, grayCurtain);
mosaic = grayCurtain;%暂时没做马赛克
mosaicCurtainTexture = Screen('MakeTexture', windowPtr, mosaic);
fixitionCurtain = grayCurtain;
fixitionCurtain( 540-5:540+5, 960-25:960+25, :) = 255;
fixitionCurtain( 540-25:540+25, 960-5:960+5, :) = 255;
fixitionCurtainTexture = Screen('MakeTexture', windowPtr, fixitionCurtain);

disp('4. Stimulate material generation accomplished!')
%%
%--------------------------------------------------------------------------
%                             5. Main loop
%--------------------------------------------------------------------------
%try
%---------------train
HideCursor();
%----------开头指导语
Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
Screen('DrawTexture', windowPtr, welTextureTraining, [], []); % Draw texture into the backbuffer
Screen('Flip', windowPtr); % show the texture in backbuffer on the screen (frontbuffer) when detected vertical retrace signal.

while KbCheck; end  % clear the keypress information in cache.
while 1
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
    if keyCode(startKey)
        Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
        Screen('Flip', windowPtr);
        break;
    elseif keyCode(quitKey)
        DropOut;
        return;
        break;
    end
end
%----------trials
for trialNumber = 1:trainNumber
    %----------刺激序列
    %-----常驻注视点
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, fixitionCurtainTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    WaitSecs(2);
    
    %-----刺激
    ShowStimulus(rhythmSpeed, ifi, windowPtr, stimulusCell{trialNumber,3}, soundWave, pahandle, fixitionCurtainTexture);
    WaitSecs(stimulusShowTime);
    %-----空屏
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    WaitSecs(stimulusVoidTime);
    
    
    %-----任务要求（按空格继续）
    if stimulusCell{trialNumber,4} == 1
        trialTexture = welTextureForward;
    else
        trialTexture = welTextureBackward;
    end
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, trialTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr); % show the texture in backbuffer on the screen (frontbuffer) when detected vertical retrace signal.
    
    
    while KbCheck; end  % clear the keypress information in cache.
    while 1
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
        if keyCode(startKey)
            Screen('FillRect', windowPtr, black);
            Screen('Flip', windowPtr);
            break;
        elseif keyCode(quitKey)
            DropOut;
            return;
            break;
        end
    end
    
    %-----呈现探针
    %-----常驻注视点
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, fixitionCurtainTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    WaitSecs(2);
    
    %-----刺激
    ShowStimulus(rhythmSpeed, ifi, windowPtr, stimulusCell{trialNumber,6}, soundWave, pahandle, fixitionCurtainTexture);
    WaitSecs(stimulusShowTime);
    %-----空屏
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    WaitSecs(stimulusVoidTime);
    
    
    %-----呈现判断界面
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, judgementTexture, [], []); % Draw texture into the backbuffer
    vblReactionStart = Screen('Flip', windowPtr);
    while KbCheck; end  % clear the keypress information in cache.
    while 1
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
        if keyCode(quitKey)
            DropOut;
            return;
            break;
        elseif keyCode(keyIndex(1))
            %按了F，表示符合条件。
            vblReactionEnd = GetSecs();%这里的单位是秒。
            judgement = 1;
            break;
        elseif keyCode(keyIndex(2))
            %按了J，不符合条件。
            vblReactionEnd = GetSecs();%这里的单位是秒。
            judgement = 2;
            break;
        end
    end
    
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    vbl = Screen('Flip', windowPtr);
    totalAnswerArray{trialNumber,7} = judgement;
    totalAnswerArray{trialNumber,8} = vblReactionEnd - vblReactionStart;
    WaitSecs( (randi(20)-10)/10 + 3 );
end

%%
%---------------test
%----------开头指导语
Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
Screen('DrawTexture', windowPtr, welTextureActual, [], []); % Draw texture into the backbuffer
Screen('Flip', windowPtr); % show the texture in backbuffer on the screen (frontbuffer) when detected vertical retrace signal.

while KbCheck; end  % clear the keypress information in cache.
while 1
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
    if keyCode(startKey)
        Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
        Screen('Flip', windowPtr);
        break;
    elseif keyCode(quitKey)
        DropOut;
        return;
        break;
    end
end
%----------trials
for trialNumber = 1+trainNumber : testNumber+trainNumber
    %----------刺激序列
    %-----常驻注视点
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, fixitionCurtainTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    WaitSecs(2);
    
    %-----刺激
    ShowStimulus(rhythmSpeed, ifi, windowPtr, stimulusCell{trialNumber,3}, soundWave, pahandle, fixitionCurtainTexture);
    WaitSecs(stimulusShowTime);
    %-----空屏
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    WaitSecs(stimulusVoidTime);
    
    
    %-----任务要求（按空格继续）
    if stimulusCell{trialNumber,4} == 1
        trialTexture = welTextureForward;
    else
        trialTexture = welTextureBackward;
    end
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, trialTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr); % show the texture in backbuffer on the screen (frontbuffer) when detected vertical retrace signal.
    
    
    while KbCheck; end  % clear the keypress information in cache.
    while 1
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
        if keyCode(startKey)
            Screen('FillRect', windowPtr, black);
            Screen('Flip', windowPtr);
            break;
        elseif keyCode(quitKey)
            DropOut;
            return;
            break;
        end
    end
    RT0 = GetSecs() - vblReactionStart;
    
    %-----呈现探针
    %-----常驻注视点
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, fixitionCurtainTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    WaitSecs(2);
    
    %-----刺激
    ShowStimulus(rhythmSpeed, ifi, windowPtr, stimulusCell{trialNumber,6}, soundWave, pahandle, fixitionCurtainTexture);
    WaitSecs(stimulusShowTime);
    %-----空屏
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    WaitSecs(stimulusVoidTime);
    
    
    %-----呈现判断界面
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, judgementTexture, [], []); % Draw texture into the backbuffer
    vblReactionStart = Screen('Flip', windowPtr);
    while KbCheck; end  % clear the keypress information in cache.
    while 1
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
        if keyCode(quitKey)
            DropOut;
            return;
            break;
        elseif keyCode(keyIndex(1))
            %按了F，表示符合条件。
            vblReactionEnd = GetSecs();%这里的单位是秒。
            judgement = 1;
            break;
        elseif keyCode(keyIndex(2))
            %按了J，不符合条件。
            vblReactionEnd = GetSecs();%这里的单位是秒。
            judgement = 2;
            break;
        end
    end
    
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    vbl = Screen('Flip', windowPtr);
    totalAnswerArray{trialNumber,7} = judgement;
    totalAnswerArray{trialNumber,8} = vblReactionEnd - vblReactionStart;
    totalAnswerArray{trialNumber,9} = RT0;
    WaitSecs( (randi(20)-10)/10 + 3 );
end

% catch
%     DropOut;
% end
%--------------------------------------------------------------------------
%                              6. Save it
%--------------------------------------------------------------------------
t=toc;
allOutcomeName = [rootDir '\Data\' answer{1} ' TenetScale ' testdate '.mat'];
save(allOutcomeName,'participantNumber','totalAnswerArray','t');
disp('6. Save it accomplished!')
sprintf('The experiment was successfully completed, and it has token %f s.',t);
DropOut;
end




%% 调用的子函数
function ShowStimulus(rhythmSpeed, ifi, windowPtr, stimSequence, soundWave, pahandle, fixitionCurtainTexture)
for ii = 1:length(stimSequence)
    aLineArray(2*ii-1) = stimSequence(ii);
    aLineArray(2*ii) = 0;
end

waitframes = 0;
Screen('DrawTexture', windowPtr, fixitionCurtainTexture, [], []); % Draw texture into the backbuffer
vbl = Screen('Flip', windowPtr);

for jj = 1:length(aLineArray)
    if aLineArray(jj) == 0
        %休止符
        Screen('DrawTexture', windowPtr, fixitionCurtainTexture, [], []); % Draw texture into the backbuffer
        vbl = Screen('Flip', windowPtr , vbl + rhythmSpeed/2 + (waitframes - 0.5) * ifi);
    else
        tempSoundWave = soundWave{aLineArray(jj)};
        %声音
        Screen('DrawTexture', windowPtr, fixitionCurtainTexture, [], []); % Draw texture into the backbuffer
        vbl = Screen('Flip', windowPtr , vbl + rhythmSpeed/2 + (waitframes - 0.5) * ifi);
        PsychPortAudio('FillBuffer', pahandle, tempSoundWave);
        PsychPortAudio('Start', pahandle, 1, 0);
    end
end
% PsychPortAudio('Stop',pahandle);
% PsychPortAudio('Close');
% MarkOut
end

function DropOut
%fclose(com1);%串口
Priority(0); %resets priority
ShowCursor();
ListenChar(0);
sca;
PsychPortAudio('Close');
PsychPortAudio('DeleteBuffer');
disp('实验结束');
end