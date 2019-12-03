function AudMotion_sEEG

% Original Script Written by Sam Weiller to localize MT+/V5
% Adapted by M.Rezk to localize MT/MST (Huk,2002)
% simplify the ALocaliser fmri experiment for ERPs

clear all;
clc

%% set trial or real experiment
% device = 'eeg';
device = 'trial';

fprintf('Connected Device is %s \n\n',device);


%% Start me up
% Get the subject Name
SubjName = input('Subject Name: ','s');
       if isempty(SubjName)
          SubjName = 'test';
       end

fprintf('Auditory ERPs \n\n')

%% Experiment Parametes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
finalWait = 1;
ISI = 0.0;             % Interstimulus Interval between events in the block.
ibi = 1.5;                                                                       % Inter-block duration in seconds (time between blocks)
% MAKE gaussian distribution of IBI later on.












numEvents = 120; 
percTarget = 10;                                                                % Percentage of trials as target
%numEventsPerBlock = 1;
%range_targets = [0 2];                                                         % range of number of targets in each block (from 2 to 5 targets in each block)
freq = 44100;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                               % 1 Cycle = one inward and outward motion together
%% Experimental Design
soundfiles = {'Static','mot_LRRL', 'mot_RLLR', 'Static_T','mot_LRRL_T', 'mot_RLLR_T'}; % order IS important
rndstim_order= getTrialSeq(numEvents, percTarget); %repmat(1:6,1,4); %SHUFFLE 2 MOTION + 1 static + 10% of targers
%[rndstim_names, rndstim_order]= getTrialSeq(numEvents, percTarget); 
Numsounds = length(rndstim_order);
stim_length = length(soundfiles);

%% InitializePsychAudio;
InitializePsychSound(1);
%OPEN AUDIO PORTS
startPsych = GetSecs();
phandle = PsychPortAudio('Open',[],[],1,freq,2);


%load the buffer
for i = 1:stim_length
    
    chosen_dir{i} = [soundfiles{i},'.wav'];
    filename = fullfile('stimuli',SubjName,chosen_dir{i}); 
    [SoundData{i},~]=audioread(filename);
    SoundData{i} = SoundData{i}';
    
end
endPsych = GetSecs - startPsych; % not sure if we need this




%% TRIGGER - OR NOT TRIGGER - HOW TRIGGER WORKS
if strcmp(device,'test')
    
    % press key
    KbWait();
    KeyIsDown=1;
    while KeyIsDown>0
        [KeyIsDown, ~, ~]=KbCheck;
    end
    
    
% TRIGGER EEG?
elseif strcmp(device,'eeg')
    fprintf('Waiting For Trigger...');
    begin_trig = GetSecs();
    
    
    
    
    
    
    
    %INSERT TIRGGER HERE ???


end

Trigger_onset = GetSecs();
fprintf('starting experiment \n');
tot_trig = Trigger_onset - begin_trig;


ExpStart = GetSecs();
hold_expStart = ExpStart;
%% Experiment Start (Main Loop)
experimentStartTime = GetSecs;

targetTime   = [];
responseKey  = [];
responseTime = [];

eventOnsets=zeros(1,numEvents);
eventEnds=zeros(1,numEvents);
eventDurations=zeros(1,numEvents);
responses=zeros(1,numEvents);

playTime = zeros(numBlocks,1);

for blocks = 1
    

    
    for iEvent = 1: numEvents
        
        timeLogger.startTime = GetSecs - experimentStartTime;        % Get the start time of the event
        timeLogger.condition = condition(iEvent);                    % Get the condition of the event (motion or static)
        timeLogger.names = names(iEvent);                            % Get the name of the event
        
        responseCount=0;

        eventOnsets(iEvent)=GetSecs-experimentStartTime;
        
        PsychPortAudio('FillBuffer',phandle,Sound);
        playTime(iEvent,1) = PsychPortAudio('Start',phandle);
         
         
         % collect button press from the keyboard
         while GetSecs() <= eventOnsets(iEvent)+ experimentStartTime + (length(Sound)/freq)

             [keyIsDown, secs, ~ ] = KbCheck();
             
             if keyIsDown
                 responseTime(end+1)= secs - experimentStartTime;
                 while keyIsDown ==1
                     [keyIsDown , ~] = KbCheck();
                 end
                 
                 responseCount = responseCount + 1;
             end
             
         end
         
         eventEnds(iEvent)=GetSecs-experimentStartTime;
         eventDurations(iEvent)=eventEnds(iEvent)-eventOnsets(iEvent);
         
         WaitSecs(ISI);
         
    end
    
    responses(blocks,1) = responseCount ;
    
    %% Get Block end and duration
    timeLogger.block(blocks).endTime = GetSecs - experimentStartTime;            % Get the time for the block end
    timeLogger.block(blocks).length  = timeLogger.block(blocks).endTime - timeLogger.block(blocks).startTime;  %Get the block duration
    
    %% Fixation cross and inter-block interval
    Screen('FillOval', w, uint8(white), fix_cord);	                             % draw fixation dot (flip erases it)
    blank_onset=Screen('Flip', w);
    WaitSecs('UntilTime', blank_onset + ibi);                                    % wait for the inter-block interval
    
end;

% At the end of the blocks wait ... secs before ending the experiment.
Screen('FillOval', w, uint8(white), fix_cord);	% draw fixation dot (flip erases it)
blank_onset=Screen('Flip', w);
WaitSecs('UntilTime', blank_onset + finalWait);


%% Save the results ('names','onsets','ends','duration') of each block
names     = cell(length(timeLogger),1);
onsets    = zeros(length(timeLogger),1);
ends      = zeros(length(timeLogger),1);
durations = zeros(length(timeLogger),1);

for i=1:length(timeLogger.block)
    names(i,1)     = timeLogger(i).names;
    onsets(i,1)    = timeLogger(i).startTime;
    ends(i,1)      = timeLogger(i).endTime;
    durations(i,1) = timeLogger(i).length;
end

%% KeyPresses and Times
% for i=length(responseKey):-1:2                                                   % responseKey gives a '1' in all frames where button was pressed, so one motor response = gives multiple consequitive '1' frames
%     if responseKey(i-1)~=0                                                       % therefore, we need to cancel consequitive '1' frames after the first button press
%         responseKey(i)=0;                                                        % we loop through the responses and remove '1's that are not preceeded by a zero
%         responseTime(i)=0;                                                       % this way, we remove the additional 1s for the same button response
%     end                                                                          % - The same concept for the responseTime
% end
% 
% for i=length(targetTime):-1:2                                                   % The same concept as responseKey adn responseTime.
%     if targetTime(i-1)~=0                                                       % Our Targets lasts 3 frames, to remove the TargetTime for the 2nd and 3rd frame
%         targetTime(i)=0;                                                        % we remove targets that are preceeded by a non-zero value
%     end                                                                          % that way, we have the time of the first frame only of the target
% end
% 
% responseKey  = responseKey(responseKey > 0);                                       % Remove zero elements from responseKey, responseTime, & targetTime
% responseTime = responseTime(responseTime > 0);
% targetTime   = targetTime(targetTime > 0);

%% Take the total exp time
PsychPortAudio('Close',pahandle);
myTotalSecs=GetSecs;
Experiment_duration = myTotalSecs - experimentStartTime;

%% Save a mat Log file
% Onsets & durations are saved in seconds.
save(['logFileFull_',SubjName,'.mat']);
save(['logFile_',SubjName,'.mat'], 'names','onsets','durations','ends','targets','responseTime','responseKey','targetTime','Experiment_duration','playTime');

fprintf('POSITION IS OVER!!\n');
end
