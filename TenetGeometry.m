function TenetGeometry()
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
itemNumber = 7;
sequenceLength = 5;
% participantNumber = '201811061199';
StimulusGeneratorGeometry(participantNumber,trainNumber,testNumber,itemNumber,sequenceLength);
load([participantNumber 'StimulusGeometry.mat'],'stimulusCell');

%--------------被试反应：
%前4列就是刺激序列，5列是按键顺序，6列是反应时（从trial指导语就开始了）
totalAnswerArray = stimulusCell;

disp('2. Get stimulus array accomplished!');
%--------------------------------------------------------------------------
%                       3. Set up PTB enviorment
%--------------------------------------------------------------------------
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
%---------------Image
rootDir = pwd; % get the path informatoin of current work directory
cd([rootDir '\GeometryStim']);
% 读取
for ii = 1:itemNumber
    GeometryPicture = imread([num2str(ii) '.png']);
    GeometryTexture(ii) = Screen('MakeTexture', windowPtr, GeometryPicture);
end

%----------load welcome words
welMatrixTraining = imread('welcomeTraining.jpg');
welTextureTraining = Screen('MakeTexture', windowPtr, welMatrixTraining);
welMatrixActual = imread('welcomeActual.jpg');
welTextureActual = Screen('MakeTexture', windowPtr, welMatrixActual);
welMatrixForward = imread('forward.jpg');
welTextureForward = Screen('MakeTexture', windowPtr, welMatrixForward);
welMatrixBackward = imread('backward.jpg');
welTextureBackward = Screen('MakeTexture', windowPtr, welMatrixBackward);
stimLine = imread('stimLine.png');
stimLineTexture = Screen('MakeTexture', windowPtr, stimLine);
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
    %-----2s注视点
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, fixitionCurtainTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    WaitSecs(2);
    stimSequence = stimulusCell{trialNumber,3};
    for stimSequenceIndex = 1:sequenceLength
        %-----刺激
        Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
        Screen('DrawTexture', windowPtr, GeometryTexture(stimSequence(stimSequenceIndex)), [], []); % Draw texture into the backbuffer
        vbl = Screen('Flip', windowPtr);
        WaitSecs(stimulusShowTime);
        %-----空屏
        Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []); % Draw texture into the backbuffer
        vbl = Screen('Flip', windowPtr);
        WaitSecs(stimulusVoidTime);
    end
    
    %-----任务要求（按空格继续）
    if stimulusCell{trialNumber,4} == 1
        trialTexture = welTextureForward;
    else
        trialTexture = welTextureBackward;
    end
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, trialTexture, [], []); % Draw texture into the backbuffer
    vblReactionStart = Screen('Flip', windowPtr); % show the texture in backbuffer on the screen (frontbuffer) when detected vertical retrace signal.
    
    
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
    
    %-----呈现一条刺激
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, stimLineTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    ShowCursor(0); 
    SetMouse(centerX, centerY, windowPtr); 
    for mouseClicksNumber = 1:sequenceLength
        %---鼠标位置判断
        %disp('Prepare To Click');
        %这个函数太慢。我们换一个。
        %[clicks,mouseX,mouseY,whichButton] = GetClicks(windowPtr);disp('click');
        button = [0 0 0];
        while ~button(1)
            [mouseX, mouseY, button] = GetMouse(windowPtr);
        end
        vblReactionEnd = GetSecs();%这里的单位是秒。
        %等这一次松手了才继续。
        while button(1)
            [~, ~, button] = GetMouse(windowPtr);
        end
        
        RT(mouseClicksNumber) = vblReactionEnd - vblReactionStart;
        fullLinkValue = MousePositionJudgment(mouseX,mouseY,itemNumber,screenSize);
        selectedSequence(mouseClicksNumber) = fullLinkValue;

    end
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    vbl = Screen('Flip', windowPtr);
    totalAnswerArray{trialNumber,5} = selectedSequence;
    totalAnswerArray{trialNumber,6} = RT;
    HideCursor();
    WaitSecs( (randi(20)-10)/10 + 3 );
end


%%
%---------------test
HideCursor();
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
    %-----2s注视点
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, fixitionCurtainTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    WaitSecs(2);
    stimSequence = stimulusCell{trialNumber,3};
    for stimSequenceIndex = 1:sequenceLength
        %-----刺激
        Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
        Screen('DrawTexture', windowPtr, GeometryTexture(stimSequence(stimSequenceIndex)), [], []); % Draw texture into the backbuffer
        vbl = Screen('Flip', windowPtr);
        WaitSecs(stimulusShowTime);
        %-----空屏
        Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []); % Draw texture into the backbuffer
        vbl = Screen('Flip', windowPtr);
        WaitSecs(stimulusVoidTime);
    end
    
    %-----任务要求（按空格继续）
    if stimulusCell{trialNumber,4} == 1
        trialTexture = welTextureForward;
    else
        trialTexture = welTextureBackward;
    end
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, trialTexture, [], []); % Draw texture into the backbuffer
    vblReactionStart = Screen('Flip', windowPtr); % show the texture in backbuffer on the screen (frontbuffer) when detected vertical retrace signal.
    
    
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
    
    %-----呈现一条刺激
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    Screen('DrawTexture', windowPtr, stimLineTexture, [], []); % Draw texture into the backbuffer
    vbl = Screen('Flip', windowPtr);
    ShowCursor(0); 
    SetMouse(centerX, centerY, windowPtr); 
    for mouseClicksNumber = 1:sequenceLength
        %---鼠标位置判断
        %disp('Prepare To Click');
        %这个函数太慢。我们换一个。
        %[clicks,mouseX,mouseY,whichButton] = GetClicks(windowPtr);disp('click');
        button = [0 0 0];
        while ~button(1)
            [mouseX, mouseY, button] = GetMouse(windowPtr);
        end
        vblReactionEnd = GetSecs();%这里的单位是秒。
        %等这一次松手了才继续。
        while button(1)
            [~, ~, button] = GetMouse(windowPtr);
        end
        
        RT(mouseClicksNumber) = vblReactionEnd - vblReactionStart;
        fullLinkValue = MousePositionJudgment(mouseX,mouseY,itemNumber,screenSize);
        selectedSequence(mouseClicksNumber) = fullLinkValue;

    end
    Screen('DrawTexture', windowPtr, grayCurtainTexture, [], []);
    vbl = Screen('Flip', windowPtr);
    totalAnswerArray{trialNumber,5} = selectedSequence;
    totalAnswerArray{trialNumber,6} = RT;
    totalAnswerArray{trialNumber,7} = RT0;
    HideCursor();
    WaitSecs( (randi(20)-10)/10 + 3 );
end
% catch
%     DropOut;
% end
%--------------------------------------------------------------------------
%                              6. Save it
%--------------------------------------------------------------------------
t=toc;
allOutcomeName = [rootDir '\Data\' answer{1} ' TenetGeometry ' testdate '.mat'];
save(allOutcomeName,'participantNumber','totalAnswerArray','t');
disp('6. Save it accomplished!')
sprintf('The experiment was successfully completed, and it has token %f s.',t);
DropOut;
end

%%调用的子函数
function fullLinkValue = MousePositionJudgment(mouseX,mouseY,itemNumber,screenSize)
%暂时只根据X的值来判断
Xbin = screenSize(3)/itemNumber;
Xclass = ceil(mouseX/Xbin);
fullLinkValue = Xclass;
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