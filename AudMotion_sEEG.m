%function AudMotion_sEEG

% Original Script Written by Sam Weiller to localize MT+/V5
% Adapted by M.Rezk to localize MT/MST (Huk,2002)
% Simplify the ALocaliser fmri experiment for ERPs

% simply run the script and press enter instead of specifying the
% SubjectName



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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Init_pause = 3;
freq = 44100;

%stim_duration = 1;                                                         % Duration of 1 sound % NEED TO UPDATE IN THE LOOP
%event_duration = stim_duration + ISI;                                      % 1 trial duration % NEED TO UPDATE IN THE LOOP

numEvents = 120;                                                            % Number of trials
percentTrials = 10;
%CONSIDER ADDING number of targets instead of percentage of targets
%numTargets = 8;                                                            % Percentage of trials as target

jitter = rand(1,numEvents);                                                 % creating jitter with uniform distribution around 1
                                                                            % MAKE uniform distribution of ISI later on.
                                                                            % average is 1.5 (after 1s sound, 1s min gap and max 2s)
ISI = 1 +jitter;                                                            % a vector of interstimulus intervals for each event
% CONSIDER MAKING JITTER BALANCED ACROSS CONDITIONS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                               % 1 Cycle = one inward and outward motion together
%% Experimental Design

% pseudorandomized events order: 2 MOTION + 1 static + 10% of targers
[Event_names, Event_order]= getTrialSeq(numEvents, percentTrials);          

% reassign it in case pseudorandomization provided less trial number
numEvents = length(Event_order); 

soundfiles = {...
    'static',...
    'mot_LRRL',...
    'mot_RLLR',...
    'static_T',...
    'mot_LRRL_T',...
    'mot_RLLR_T'}; 

numcondition = length(soundfiles);

condition = {...
    'static',...
    'motion',...
    'motion',...
    'static',...
    'motion',...
    'motion'};

isTarget = [0 0 0 1 1 1];

%% Open parallel port 
if strcmp(device,'eeg')
    openparallelport('D010');
elseif strcmp(device,'trial')
    %assign number of trails to 15 
    numEvents = 15;
end

%% InitializePsychAudio;
InitializePsychSound(1);

% open audio port
pahandle = PsychPortAudio('Open',[],[],1,freq,2);


%load the buffer
for icon = 1:numcondition
    
    chosen_file{icon} = [soundfiles{icon},'.wav'];
    filename = fullfile('stimuli',SubjName,chosen_file{icon}); 
    [SoundData{icon},~]=audioread(filename);
    SoundData{icon} = SoundData{icon}';
    
end


fprintf('starting experiment... \n');


%% Experiment Start
experimentStartTime = GetSecs();
hold_expStart = experimentStartTime;
WaitSecs(Init_pause);
%% Loop starts

%targetTime   = [];


eventOnsets =       zeros(1,numEvents);
eventEnds =         zeros(1,numEvents);
eventDurations =    zeros(1,numEvents);
responses =         zeros(1,numEvents);
playTime =          zeros(1,numEvents);



for iEvent = 1:numEvents
    startEvent = GetSecs();
    responseKey  = [];
    responseTime = [];

    timeLogger(iEvent).startTime = GetSecs - experimentStartTime;                       % Get the start time of the event
    timeLogger(iEvent).condition = condition(Event_order(iEvent));                      % Get the condition of the event (motion or static)
    timeLogger(iEvent).names = soundfiles(Event_order(iEvent));                         % Get the name of the event
    timeLogger(iEvent).ISI = ISI(iEvent);                                               % Get the ISI of the event

    
    Sound = SoundData{Event_order(iEvent)};                                     % Load the chosen sound
        
    trigger = Event_order(iEvent);                                              %assign trigger to which sound will be played 
    
    eventOnsets(iEvent)=GetSecs-experimentStartTime;                            % Get the onset time
    
    PsychPortAudio('FillBuffer',pahandle,Sound);                                % fill the buffer 
    
    %send the trigger
    if strcmp(device,'eeg')
        sendparallelbyte(trigger);
        
        %Play the sound
        playTime(1,iEvent) = PsychPortAudio('Start', pahandle, [],[],1,startEvent+(length(Sound)/freq));
        
        %reset the parallel port
        sendparallelbyte(0);
        
    else
        %Play the sound
        playTime(1,iEvent) = PsychPortAudio('Start', pahandle, [],[],1,startEvent+(length(Sound)/freq));
        
    end
    
    % playTime(iEvent,1) = PsychPortAudio('Start',phandle);
    % startTime = GetSecs();

    %%Wait for the ISI and register the responseKey
    while (GetSecs-(playTime(1,iEvent)+(length(Sound)/freq)))<=(ISI(iEvent))
        
        [keyIsDown, secs, keyCode] = KbCheck(-1);
        
        if keyIsDown
            
            responseKey = KbName(find(keyCode));
            responseTime = secs - experimentStartTime;
            
            %ecs key press - stop playing the sounds//script
            if strcmp(responseKey,'ESCAPE')==1
                % find(keyCode)== KbName('esc')
                % If the script is stopped while a sequence is being
                % played, it sends trigger 7
                PsychPortAudio('Close', pahandle);
                if strcmp(device,'eeg') %if sEEG (don't do that in the pc)
                    sendparallelbyte(7)% triggers code for escape is 30
                    sendparallelbyte(0)
                end
                return
            end
        end
    end


       
%     %collect button press from the keyboard
%     while GetSecs() <= eventOnsets(iEvent)+ experimentStartTime + (length(Sound)/freq)
%         
%         [keyIsDown, secs, ~ ] = KbCheck();
%         
%         if keyIsDown
%             responseTime(end+1)= secs - experimentStartTime;
%             while keyIsDown ==1
%                 [keyIsDown , ~] = KbCheck();
%             end
%             
%             responseCount = responseCount + 1;
%         end
%         
%     end
    
    eventEnds(iEvent)=GetSecs-experimentStartTime;
    eventDurations(iEvent)=eventEnds(iEvent)-eventOnsets(iEvent);
    
  %  WaitSecs(ISI(iEvent)); % either use WaitSecs(ISI) or below while loop
  
    %below while loop does not work atm - 03.12.2019
    %     while eventDurations(iEvent)<(event_duration)                                % getting rid off possible delays -> wait in the while loop
    %     end                                                                          % for the exact length of stimulus + response gap = eventDuration
    %
    
    % timeLogger(iEvent).length  = timeLogger(iEvent).endTime - timeLogger(iEvent).startTime;  %Get the total trial duration
    timeLogger(iEvent).length  = eventDurations(iEvent);                               %Get the total trial duration
    timeLogger(iEvent).endTime = eventEnds(iEvent);                                    % Get the time for the block end
    timeLogger(iEvent).responseTime = responseTime;
    timeLogger(iEvent).response = responseKey;
    timeLogger(iEvent).isTarget = isTarget(Event_order(iEvent));

    timeLogger(iEvent).whichtrigger = trigger;
    
    
    
    % consider adding WaitSec for ending?
    % what would happen if esc key pressed? the logfile will be saved?
    % CONSIDER what happens in case of buttonpress>1 time??
end



%% Save the results ('names','onsets','ends','duration') of each block
names     = cell(length(timeLogger),1);
onsets    = zeros(length(timeLogger),1);
ends      = zeros(length(timeLogger),1);
durations = zeros(length(timeLogger),1);

for i=1:length(timeLogger)
    names(i,1)     = timeLogger(i).names;
    onsets(i,1)    = timeLogger(i).startTime;
    ends(i,1)      = timeLogger(i).endTime;
    durations(i,1) = timeLogger(i).length;
end



%% KeyPresses and Times
% responseKey gives a '1' in all frames where button was pressed, so one motor response = gives 
% multiple consequitive '1' frames therefore, we need to cancel consequitive '1' frames after the 
% first button press we loop through the responses and remove '1's that are not preceeded by a zero
% this way, we remove the additional 1s for the same button response
% - The same concept for the responseTime
% The same concept as responseKey adn responseTime.
% Our Targets lasts 3 frames, to remove the TargetTime for the 2nd and 3rd frame
% we remove targets that are preceeded by a non-zero value
% that way, we have the time of the first frame only of the target

% for i=length(responseKey):-1:2                                                    
%     if responseKey(i-1)~=0                                                       
%         responseKey(i)=0;                                                        
%         responseTime(i)=0;                                                       
%     end                                                                         
% end
%
% for i=length(targetTime):-1:2                                                   
%     if targetTime(i-1)~=0                                                       
%         targetTime(i)=0;                                                        
%     end                                                                          
% end

% Remove zero elements from responseKey, responseTime, & targetTime
% responseKey  = responseKey(responseKey > 0); 
% responseTime = responseTime(responseTime > 0);
% targetTime   = targetTime(targetTime > 0);



%% Take the total exp time
PsychPortAudio('Close',pahandle);
Experiment_duration = GetSecs - experimentStartTime;



%% Save a mat Log file
% Onsets & durations are saved in seconds.
save(['logFileFull_', SubjName, '.mat']);
save(['logFile_', SubjName, '.mat'], ...
    'names', 'onsets', 'durations', 'ends', 'responseTime', ...
    'responseKey', 'Experiment_duration', 'playTime');

%targets? targetTime?
%save(['logFile_',SubjName,'.mat'], 'names','onsets','durations','ends', ...
%  'targets','responseTime','responseKey','targetTime','Experiment_duration','playTime');

fprintf('Sequence IS OVER!!\n');
