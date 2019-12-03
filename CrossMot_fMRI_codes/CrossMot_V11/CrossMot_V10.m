clc;
clear all;

%% CHANGE HERE FOR VOICES VOLUME
%load(fullfile('Siri','Siri_0.mat')) % lowest voices
%load(fullfile('Siri','Siri_3.mat'))
load(fullfile('Siri','Siri_6.mat')) % loudest voices

% Experiment takes 300 seconds (without the Trigger TRs)
% if TR=2  , then we collect 150 + 4 Triggers = 154 TRs at least per run
% if TR=2.5, then we collect 120 + 4 Triggers = 124 TRs at least per run
%% loadAudiofiles
% if you would like to test on a part of the screen, change to 1;
TestingSmallScreen = 0;

Cfg.device = 'Scanner';
%Cfg.device = 'PC';

if strcmp(Cfg.device,'PC')
    fprintf('\n\n\n\n')
    fprintf('#################################### \n')
    fprintf('##  THIS IS NOT THE SCANNER CODE  ## \n')
    fprintf('#################################### \n\n')
end

%% Setting
Cfg.experimentType = 'Dots';   % Visual modality is in RDKs

Cfg.possibleModalities = {'visual','auditory'}; %
Cfg.possibleDirections = [0 90 180 270]; %             % possible motion angles  (-1 is for static)
Cfg.names = {'right','up','left','down'};      %      % 0= Right   90= Up    180= Left    270=down

Cfg.numRepetitions         = 1 ;
Cfg.speedEvent             = 4  ;
Cfg.speedTarget            = 8 ;
Cfg.numEventsPerBlock      = 10 ;
Cfg.maxNumTargetPerBlock   = 0 ;
Cfg.maxNumFixationTargetPerBlock = 2 ;
Cfg.eventDuration          = 1.2 ;
Cfg.interstimulus_interval = 0.1 ;                   % time between events in secs
Cfg.interBlock_interval    = 6 ;
Cfg.response_time          = 1 ;

PreSiriSilence = 0.5;
%Set below
%Cfg.numTargetPerBlock      = randi([0 Cfg.maxNumTargetPerBlock],1);  % Random number (n) of targets between zero and maximum                                                      % in each block in all the run
%Cfg.numFixationTargets     = randi([0 Cfg.maxNumTargetPerBlock],1);

Cfg.fixationChangeDuration = 0.15;                    % in secs

onsetDelay = 5;                                      % number of seconds before the motion stimuli are presented
endDelay = 5;                                        % number of seconds after the end all the stimuli before ending the run

%% Parameters for monitor setting
monitor_width  	 = 42;                            % Monitor Width in cm
screen_distance  = 134;                           % Distance from the screen in cm
diameter_aperture= 8;                             % diameter/length of side of aperture in Visual angles

Cfg.coh = 1;                                      % Coherence Level (0-1)
dotSize = 0.12;                                   % dot Size (dot width) in visual angles.
Cfg.maxDotsPerFrame = 300;                        % Maximum number dots per frame (Number must be divisible by 3)
Cfg.dotLifeTime = 0.2;                            % Dot life time in seconds
Cfg.dontclear = 0;
Cfg.dotSize = 0.1;

% manual displacement of the fixation cross
xDisplacementFixCross = 0 ; 
yDisplacementFixCross = 0 ;

if mod(Cfg.maxDotsPerFrame,3) ~= 0
    error('Number of dots should be divisible by 3.')
end

%% Fixation Cross parameters
% Used Pixels here since it really small and can be adjusted during the experiment
Cfg.fixCrossDimPix = 10;                            % Set the length of the lines (in Pixels) of the fixation cross
Cfg.lineWidthPix = 4;                               % Set the line width (in Pixels) for our fixation cross

%% Color Parameters
White = [255 255 255];
Black = [ 0   0   0 ];
Grey  = mean([Black;White]);

Cfg.textColor           = White ;
Cfg.Background_color    = Black  ;
Cfg.fixationCross_color = White ;
Cfg.dotColor            = White ;

% Get Subject Name and run number
subjectName = input('Enter Subject Name: ','s');
if isempty(subjectName)
    subjectName = 'trial';
end

runNumber = input('Enter the run Number: ','s');
if isempty(runNumber)
    runNumber = 'trial';
end

HideCursor;

if exist(fullfile('logfiles',[subjectName,'_run_',num2str(runNumber),'.mat']),'file')>0
    error('This file is already present in your logfiles. Delete the old file or rename your run!!')
end

%%  Experiment

try % safety loop: close the screen if code crashes
    
AssertOpenGL;

% any preliminary stuff
%%%%%%%%%%%%%%%%%%%%%%%%%
% Select screen with maximum id for output window:
screenid = max(Screen('Screens'));
% Open a fullscreen, onscreen window with gray background. Enable 32bpc
% floating point framebuffer via imaging pipeline on it.
PsychImaging('PrepareConfiguration');
%PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');

Screen('Preference','SkipSyncTests', 0);

if TestingSmallScreen
    [Cfg.win, Cfg.winRect] = PsychImaging('OpenWindow', screenid, Cfg.Background_color,  [0,0, 480, 270]);
else
    [Cfg.win, Cfg.winRect] = PsychImaging('OpenWindow', screenid, Cfg.Background_color);
end

if strcmp(Cfg.device,'Scanner')                    % if this is in the scanner
    Cfg.winRect(1,4) = Cfg.winRect(1,4)*2/3 ;      % remove the lower 1/3 of the screen because of the coil
end                                                % hides the lower part of the screen

% Get the Center of the Screen
Cfg.center = [Cfg.winRect(3), Cfg.winRect(4)]/2;

%% Fixation Cross
xCoords = [-Cfg.fixCrossDimPix Cfg.fixCrossDimPix 0 0] + xDisplacementFixCross;
yCoords = [0 0 -Cfg.fixCrossDimPix Cfg.fixCrossDimPix] + yDisplacementFixCross;
Cfg.allCoords = [xCoords; yCoords];

% Query frame duration
Cfg.ifi = Screen('GetFlipInterval', Cfg.win);
Cfg.monRefresh = 1/Cfg.ifi;

% monitor distance
Cfg.mon_horizontal_cm  	= monitor_width;                         % Width of the monitor in cm
Cfg.view_dist_cm 		= screen_distance;                       % Distance from viewing screen in cm
Cfg.apD = diameter_aperture;                                     % diameter/length of side of aperture in Visual angles


% Everything is initially in coordinates of visual degrees, convert to pixels
% (pix/screen) * (screen/rad) * rad/deg
V = 2* (180 * (atan(Cfg.mon_horizontal_cm/(2*Cfg.view_dist_cm)) / pi));
Cfg.ppd = Cfg.winRect(3) / V ;

Cfg.d_ppd = floor(Cfg.apD * Cfg.ppd);                            % Covert the aperture diameter to pixels
Cfg.dotSize = floor (Cfg.ppd * Cfg.dotSize);                          % Covert the dot Size to pixels

%%
% Enable alpha-blending, set it to a blend equation useable for linear
% superposition with alpha-weighted source.
Screen('BlendFunction', Cfg.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% Initially sync us to VBL at start of animation loop.

vbl = Screen('Flip', Cfg.win);

% Text options/
% Select specific text font, style and size:
Screen('TextFont',Cfg.win, 'Courier New');
Screen('TextSize',Cfg.win, 18);
Screen('TextStyle', Cfg.win, 1);


iRun = 0 ;
while iRun < 3
    % randomise response order
    SiriShuffled=Shuffle(Siri);
    
    % Loads the audio files from the the folder (Audio/SubjectName)
    [soundData, FS, phandle]=loadAudioFiles(fullfile('Audio',subjectName),subjectName);
    fprintf('\n\n')
        
    %% Experimental Design
    Cfg.numTargetPerBlock      = randi([0 Cfg.maxNumTargetPerBlock],1);  % Random number (n) of targets between one and maximum                                                      % in each block in all the run
    Cfg.numFixationTargets     = randi([1 Cfg.maxNumFixationTargetPerBlock],1);

    directions=[];
    speeds=[];
    fixationTargets=[];
    
    [directions, speeds, modalities,fixationTargets] = exp_design(Cfg);

    numBlocks = size(directions,1);

    %%
    %runNumber = num2str(str2num(InitialRunNumb)+ iRun);
    
    %%%%%%%%%%%%%%%%%%%%%%
    % experiment
    %%%%%%%%%%%%%%%%%%%%%%
    %Instructions
    DrawFormattedText(Cfg.win,'Press for 1-RED fixation 2- DIRECTION (after)\n\n',...
    'center', 'center', Cfg.textColor);
    Screen('Flip', Cfg.win);
    
    %[KeyIsDown, ~, ~]=KbCheck;
    KbWait();
    KeyIsDown=1;
    while KeyIsDown>0
        [KeyIsDown, ~, ~]=KbCheck;
    end
    
    %% Empty vectors and matrices for speed
    blockNames     = cell(numBlocks,1);
    blockOnsets    = zeros(numBlocks,1);
    blockEnds      = zeros(numBlocks,1);
    blockDurations = zeros(numBlocks,1);
    
    eventOnsets    = zeros(numBlocks,Cfg.numEventsPerBlock);
    eventEnds      = zeros(numBlocks,Cfg.numEventsPerBlock);
    eventDurations = zeros(numBlocks,Cfg.numEventsPerBlock);
    
    SiriOnset = zeros(numBlocks,1);
    SiriEnds = zeros(numBlocks,1);
    SiriDurations = zeros(numBlocks,1);
    SiriCorrectResp = zeros(numBlocks,1); 
    SiriSubjResponse = zeros(numBlocks,1); 
    SiriResponseTime = zeros(numBlocks,1);
       
    allResponses = [] ;
    %% Wait for Trigger from Scanner
    % open Serial Port "SerPor" - COM1 (BAUD RATE: 11520)
    
    if strcmp(Cfg.device,'PC')
        DrawFormattedText(Cfg.win,'Waiting For Trigger',...
            'center', 'center', Cfg.textColor);
        Screen('Flip', Cfg.win);
        
        % press key
        KbWait();
        KeyIsDown=1;
        while KeyIsDown>0
            [KeyIsDown, ~, ~]=KbCheck;
        end
        
    elseif strcmp(Cfg.device,'Scanner')
        DrawFormattedText(Cfg.win,'Waiting For Trigger','center', 'center', Cfg.textColor);
        Screen('Flip', Cfg.win);
        Cfg.SerPor = MT_portAndTrigger;
        Screen('Flip', Cfg.win);
    end
    
    Screen('DrawLines', Cfg.win, Cfg.allCoords,Cfg.lineWidthPix, [255 255 255] , [Cfg.center(1) Cfg.center(2)], 1);
    Screen('Flip',Cfg.win);
    
    %% txt logfiles
    if ~exist('logfiles','dir')
        mkdir('logfiles')
    end
    
    BlockTxtLogFile = fopen(fullfile('logfiles',[subjectName,'_run_',num2str(str2num(runNumber)+iRun),'_Blocks.txt']),'w');
    fprintf(BlockTxtLogFile,'%12s %12s %12s %12s %12s %12s %12s %12s %12s %12s \n',...
        'BlockNumber','Modality','Direction','Onset','End','Duration','SiriOnset','SiriDuration','SiriCorrect','SiriSubj');
    
    EventTxtLogFile = fopen(fullfile('logfiles',[subjectName,'_run_',num2str(str2num(runNumber)+iRun),'_Events.txt']),'w');
    fprintf(EventTxtLogFile,'%12s %12s %12s %12s %18s %12s %12s %12s %12s \n',...
        'BlockNumber','EventNumber','Modality','Direction', 'IsFixationTarget','Speed','Onset','End','Duration');
    
    ResponsesTxtLogFile = fopen(fullfile('logfiles',[subjectName,'_run_',num2str(str2num(runNumber)+iRun),'_Responses.txt']),'w');
    fprintf(ResponsesTxtLogFile,'%12s \n','Responses');
    
    %% Experiment Start
    Cfg.Experiment_start = GetSecs;
    
    WaitSecs(onsetDelay);
    
    %% For Each Block
    for iBlock = 1:numBlocks
                     
        fprintf('Running Block %.0f \n',iBlock)
        
        blockOnsets(iBlock,1)= GetSecs-Cfg.Experiment_start;
        
        % For each event in the block
        for iEventsPerBlock = 1:Cfg.numEventsPerBlock
            
            iEventDirection = directions(iBlock,iEventsPerBlock);       % Direction of that event
            iEventSpeed = speeds(iBlock,iEventsPerBlock);               % Speed of that event
            iEventDuration = Cfg.eventDuration ;                        % Duration of normal events
            iEventIsFixationTarget = fixationTargets(iBlock,iEventsPerBlock);
            
            % Event Onset
            eventOnsets(iBlock,iEventsPerBlock) = GetSecs-Cfg.Experiment_start;
            
            %% Different Modalities
            
            %%%%%%%%%%%%%%%%%%% 
            % Visual modality % 
            %%%%%%%%%%%%%%%%%%%
            
            if strcmp(modalities{iBlock},'visual')           
                % If it is the visual RDK modality 
                
                if iEventSpeed == Cfg.speedTarget                          % check if its a target event
                    iEventDuration = iEventDuration/2;                     % divide its duration by 2 (because its faster by 2)
                end
                
                % play the dots
                responseTimeWithinEvent = DoDotMo( Cfg, iEventDirection, iEventSpeed, iEventDuration, iEventIsFixationTarget);
                
            %%%%%%%%%%%%%%%%%%%%%
            % Auditory modality % 
            %%%%%%%%%%%%%%%%%%%%%
                
            elseif strcmp(modalities{iBlock},'auditory')
                
                playedAudio = playAudio(Cfg,phandle,soundData,iEventSpeed,iEventDirection);       % play Audio

                % wait for the duration of the audiofile to finish playing and
                % collect any responses if any existed.
                
                
                responseTimeWithinEvent =[];
                while GetSecs() <= eventOnsets(iBlock,iEventsPerBlock)+ Cfg.Experiment_start+ (length(playedAudio)/FS)
                    
                    % fixation cross change
                    if GetSecs < (eventOnsets(iBlock,iEventsPerBlock)+ Cfg.Experiment_start+Cfg.fixationChangeDuration) && iEventIsFixationTarget==1
                        Screen('DrawLines', Cfg.win, Cfg.allCoords,Cfg.lineWidthPix, [255 0 0] , [Cfg.center(1) Cfg.center(2)], 1);  % Draw the fixation cross
                    else
                        Screen('DrawLines', Cfg.win, Cfg.allCoords,Cfg.lineWidthPix, [255 255 255] , [Cfg.center(1) Cfg.center(2)], 1);  % Draw the fixation cross
                    end
                    Screen('Flip', Cfg.win,0,Cfg.dontclear);
                    
                    %% Responses
                    if strcmp(Cfg.device,'PC')
                        [keyIsDown, secs, keyCode] = KbCheck;
                        
                        %%%%
                        % 1- added (end+1) to the responseTimeWithinEvent
                        % 2- put the fprintf command in the loop
                        %%%%
                        
                        % if key is pressed
                        if keyIsDown==1
                            responseTimeWithinEvent(end+1) = secs - Cfg.Experiment_start;  % Get time of pressing
                            fprintf(ResponsesTxtLogFile,'%8.6f \n',responseTimeWithinEvent(end));
                            
                            
                            while keyIsDown ==1
                                [keyIsDown, ~, ~] = KbCheck;                    % and wait for key release
                            end
                        end
                    elseif strcmp(Cfg.device,'Scanner')                        
                        [sbutton,secs]= TakeSerialButton(Cfg.SerPor);
                        
                        %%%%
                        % 1- added (end+1) to the responseTimeWithinEvent
                        % 2- put the fprintf command in the loop
                        %
                        % 3 - Commented the loop for waiting for button
                        % release
                        %%%%
                        if sbutton~=0
                            responseTimeWithinEvent(end+1)= secs - Cfg.Experiment_start; 
                            fprintf(ResponsesTxtLogFile,'%8.6f \n',responseTimeWithinEvent(end));
                            
                            % while you are pressing, wait till it is
                            % released
%                             while  sbutton ~= 0
%                                 [sbutton,secs]= TakeSerialButton(Cfg.SerPor);
%                             end
                            %%%%%%%%%%%%%%%%%%%%%
                                
                        end
                    end
                end
            end
            

            %% Event End and Duration
            eventEnds(iBlock,iEventsPerBlock) = GetSecs-Cfg.Experiment_start;
            eventDurations(iBlock,iEventsPerBlock) = eventEnds(iBlock,iEventsPerBlock) - eventOnsets(iBlock,iEventsPerBlock);
            
            % concatenate the new event responses with the old responses vector
            allResponses = [allResponses responseTimeWithinEvent] ;
            
            Screen('DrawLines', Cfg.win, Cfg.allCoords,Cfg.lineWidthPix, [255 255 255] , [Cfg.center(1) Cfg.center(2)], 1);
            Screen('Flip',Cfg.win);
            
            
            %% Event txt_Logfile
            fprintf(EventTxtLogFile,'%12.0f %12.0f %12s %12.0f %18.0f %12.2f %12.5f %12.5f %12.5f \n',...
                iBlock,iEventsPerBlock,modalities{iBlock},iEventDirection,iEventIsFixationTarget,iEventSpeed,eventOnsets(iBlock,iEventsPerBlock),eventEnds(iBlock,iEventsPerBlock),eventDurations(iBlock,iEventsPerBlock));
            
            % wait for the inter-stimulus interval
            WaitSecs(Cfg.interstimulus_interval);
        end
        
        blockEnds(iBlock,1)= GetSecs-Cfg.Experiment_start;          % End of the block Time
        blockDurations(iBlock,1)= blockEnds(iBlock,1) - blockOnsets(iBlock,1); % Block Duration
        
        %Screen('DrawTexture',Cfg.win,imagesTex.Event(1));
        Screen('DrawLines', Cfg.win, Cfg.allCoords,Cfg.lineWidthPix, [255 255 255] , [Cfg.center(1) Cfg.center(2)], 1);
        Screen('Flip',Cfg.win);
       
        %% Siri 
        SiriSound = SiriShuffled(iBlock).Y;
        SiriSequence = SiriShuffled(iBlock).Seq;
        
        if directions(iBlock,1)==0;
            SiriCorrectResp(iBlock,1) = find(strcmp(SiriSequence,'R'));
        elseif directions(iBlock,1)==180;
            SiriCorrectResp(iBlock,1) = find(strcmp(SiriSequence,'L'));
        elseif directions(iBlock,1)==90;
            SiriCorrectResp(iBlock,1) = find(strcmp(SiriSequence,'U'));
        elseif directions(iBlock,1)==270;    
            SiriCorrectResp(iBlock,1) = find(strcmp(SiriSequence,'D'));
        end
        
        %%%%%%%%%%%%
        %play siri and get responses
        PsychPortAudio('FillBuffer',phandle,SiriSound);        % prepare right wave file
        
        WaitSecs(PreSiriSilence);
        
        SiriOnset (iBlock,1) = GetSecs-Cfg.Experiment_start;

        PsychPortAudio('Start',phandle,[],[],[]);
        
        % While the audio Siri is running, check for responses
        while GetSecs <=  Cfg.Experiment_start + SiriOnset(iBlock,1) + ((length(SiriSound)/FS))
            
            % If PC 
            if strcmp(Cfg.device,'PC')
                [keyIsDown, secs, keyCode] = KbCheck;
               
                % if key is pressed
                if keyIsDown==1
                    SiriResponseTime(iBlock,1) = secs - Cfg.Experiment_start;  % Get time of pressing
                    
                    % Assign subject response, if in first quarter = 1, if
                    % 2nd quarter = 2 , etc ...
                    if SiriResponseTime(iBlock,1) <= (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(1/4)))
                        SiriSubjResponse(iBlock,1) = 1;
                    elseif SiriResponseTime(iBlock,1) <= (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(2/4))) && SiriResponseTime(iBlock,1) > (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(1/4)))
                        SiriSubjResponse(iBlock,1) = 2;
                    elseif SiriResponseTime(iBlock,1) <= (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(3/4))) && SiriResponseTime(iBlock,1) > (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(2/4)))
                        SiriSubjResponse(iBlock,1) = 3;
                    elseif SiriResponseTime(iBlock,1) <= (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(4/4))) && SiriResponseTime(iBlock,1) > (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(3/4)))
                        SiriSubjResponse(iBlock,1) = 4;
                    end
                    
                    while keyIsDown ==1     
                        [keyIsDown, ~, ~] = KbCheck;                    % and wait for key release
                    end
                end
            
            % if the scanner     
            elseif strcmp(Cfg.device,'Scanner')
                
                [sbutton,secs]= TakeSerialButton(Cfg.SerPor);
                if sbutton ~= 0
                    SiriResponseTime(iBlock,1)= secs - Cfg.Experiment_start;
                end
                    
                if SiriResponseTime(iBlock,1) <= (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(1/4)))
                    SiriSubjResponse(iBlock,1) = 1;
                elseif SiriResponseTime(iBlock,1) <= (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(2/4))) && SiriResponseTime(iBlock,1) > (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(1/4)))
                    SiriSubjResponse(iBlock,1) = 2;
                elseif SiriResponseTime(iBlock,1) <= (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(3/4))) && SiriResponseTime(iBlock,1) > (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(2/4)))
                    SiriSubjResponse(iBlock,1) = 3;
                elseif SiriResponseTime(iBlock,1) <= (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(4/4))) && SiriResponseTime(iBlock,1) > (SiriOnset(iBlock,1)+((length(SiriSound)/FS)*(3/4)))
                    SiriSubjResponse(iBlock,1) = 4;
                end
                
            end
        end
        
        %%%%%%%%%%%%
        SiriEnds(iBlock,1)= GetSecs-Cfg.Experiment_start;          % End of the block Time
        SiriDurations(iBlock,1)= SiriEnds(iBlock,1) - SiriOnset (iBlock,1); % Block Duration
        
        WaitSecs(Cfg.interBlock_interval)
        
         %% Block txt_Logfile
        fprintf(BlockTxtLogFile,'%12.0f %12s %12.0f %12f %12f %12f %12f %12f %12.0f %12.0f \n',...
        iBlock,modalities{iBlock},iEventDirection,blockOnsets(iBlock,1),blockEnds(iBlock,1),blockDurations(iBlock,1),SiriOnset(iBlock,1),SiriDurations(iBlock,1),SiriCorrectResp(iBlock,1),SiriSubjResponse(iBlock,1));
                
    end
    
    % Give each block a name (Motion Direction)
    blockDirections = directions(:,1);
    
    blockNames(blockDirections == 0   & strcmp(modalities,'auditory')) = {'A_R'};
    blockNames(blockDirections == 90  & strcmp(modalities,'auditory')) = {'A_U'};
    blockNames(blockDirections == 180 & strcmp(modalities,'auditory')) = {'A_L'};
    blockNames(blockDirections == 270 & strcmp(modalities,'auditory')) = {'A_D'};
    blockNames(blockDirections == -1  & strcmp(modalities,'auditory')) = {'A_S'};
    
    blockNames(blockDirections == 0   & strcmp(modalities,'visual')) = {'V_R'};
    blockNames(blockDirections == 90  & strcmp(modalities,'visual')) = {'V_U'};
    blockNames(blockDirections == 180 & strcmp(modalities,'visual')) = {'V_L'};
    blockNames(blockDirections == 270 & strcmp(modalities,'visual')) = {'V_D'};
    blockNames(blockDirections == -1  & strcmp(modalities,'visual')) = {'V_S'};
    
    
    % Assign the targets onsets (higher speed and change in fixation and sort
    % them) to one variable to used later for behavoiral assessment
    targetOnsets = sort([eventOnsets(fixationTargets==1) ; eventOnsets(speeds==Cfg.speedTarget)]);
    
    
    % End of the run for the BOLD to go down
    WaitSecs(endDelay);
    
    % close txt log files
    fclose(BlockTxtLogFile);
    fclose(EventTxtLogFile);
    fclose(ResponsesTxtLogFile);
    
    
    TotalExperimentTime = GetSecs-Cfg.Experiment_start
    
    %% Save mat log files
    save(fullfile('logfiles',[subjectName,'_run_',num2str(str2num(runNumber)+iRun),'_all.mat']))
    
    save(fullfile('logfiles',[subjectName,'_run_',num2str(str2num(runNumber)+iRun),'.mat']),...
        'Cfg','allResponses','blockDirections','blockDurations','blockNames','blockOnsets',...
        'SiriOnset','SiriDurations','SiriCorrectResp','SiriSubjResponse')
    
    %% Close serial port of the scanner
    if strcmp(Cfg.device,'Scanner')
        CloseSerialPort(Cfg.SerPor);
    end
        
    iRun = iRun+1;
    
end

% Close the screen
clear Screen;

catch              % if code crashes, closes serial port and screen
    clear Screen;
    if strcmp(Cfg.device,'Scanner')
        CloseSerialPort(Cfg.SerPor);
    end
    error(lasterror) % show default error
end