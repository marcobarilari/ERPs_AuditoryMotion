%function AudMotion_sEEG

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
Init_pause = 3;
ISI = 1.5;                                                                      % Interstimulus Interval between events in the block.
% MAKE gaussian distribution of ISI later on.











%stim_duration = 1;                                                             % Duration of 1 sound % NEED TO UPDATE IN THE LOOP
%event_duration = stim_duration + ISI;                                          % 1 trial duration % NEED TO UPDATE IN THE LOOP
numEvents = 120;                                                                % Number of trials
percTarget = 10;                                                                % Percentage of trials as target
freq = 44100;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                               % 1 Cycle = one inward and outward motion together
%% Experimental Design
soundfiles = {'Static','mot_LRRL', 'mot_RLLR', 'Static_T',...
              'mot_LRRL_T', 'mot_RLLR_T'};                                      % order IS important
condition = {'Static','motion','motion','Static','motion','motion'};
isTarget = [0 0 0 1 1 1];

Event_order= getTrialSeq(numEvents, percTarget);                                %pseudorandomized events order: 2 MOTION + 1 static + 10% of targers
%[rndstim_names, rndstim_order]= getTrialSeq(numEvents, percTarget);
numEvents = length(Event_order);                                                %reassign it in case pseudorandomization provided less trial number
numcondition = length(soundfiles);


%% InitializePsychAudio;
InitializePsychSound(1);
%OPEN AUDIO PORTS
startPsych = GetSecs();
phandle = PsychPortAudio('Open',[],[],1,freq,2);


%load the buffer
for icon = 1:numcondition
    
    chosen_file{icon} = [soundfiles{icon},'.wav'];
    filename = fullfile('stimuli',SubjName,chosen_file{icon}); 
    [SoundData{icon},~]=audioread(filename);
    SoundData{icon} = SoundData{icon}';
    
end
endPsych = GetSecs - startPsych; % not sure if we need this




%% TRIGGER - OR NOT TRIGGER - HOW TRIGGER WORKS
begin_trig = GetSecs();
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
    
    
    
    
    %%%%%%%%
    
    %INSERT TIRGGER HERE ???
    
    %%%%%%%%  
    

end


Trigger_onset = GetSecs();
fprintf('starting experiment \n');
tot_trig = Trigger_onset - begin_trig;

%% Experiment Start
experimentStartTime = GetSecs();
hold_expStart = experimentStartTime;
WaitSecs(Init_pause);
%% Loop starts

targetTime   = [];
responseKey  = [];
responseTime = [];

eventOnsets=zeros(1,numEvents);
eventEnds=zeros(1,numEvents);
eventDurations=zeros(1,numEvents);
responses=zeros(1,numEvents);
playTime = zeros(1,numEvents);



for iEvent = 1:5 %numEvents
    startEvent = GetSecs();
    timeLogger(iEvent).startTime = GetSecs - experimentStartTime;                       % Get the start time of the event
    timeLogger(iEvent).condition = condition(Event_order(iEvent));                      % Get the condition of the event (motion or static)
    timeLogger(iEvent).names = soundfiles(Event_order(iEvent));                         % Get the name of the event
    responseCount=0;
    
    Sound = SoundData{Event_order(iEvent)};                                     % Load the chosen sound
    %%%%%%
    eventOnsets(iEvent)=GetSecs-experimentStartTime;                            % Get the onset time
    
    PsychPortAudio('FillBuffer',phandle,Sound);                                % %Play the sound
    playTime(1,iEvent) = PsychPortAudio('Start', phandle, [],[],1,startEvent+(length(Sound)/freq)); %
    % playTime(iEvent,1) = PsychPortAudio('Start',phandle);
    % startTime = GetSecs();
    %%%%%%
    
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
    
    WaitSecs(ISI);                                                             % either use WaitSecs(ISI) or below while loop
    
    %below while loop does not work atm - 03.12.2019
%     while eventDurations(iEvent)<(event_duration)                                % getting rid off possible delays -> wait in the while loop
%     end                                                                          % for the exact length of stimulus + response gap = eventDuration
%     
    
    responses(iEvent) = responseCount ;
    timeLogger(iEvent).endTime = GetSecs - experimentStartTime;                 % Get the time for the block end
    timeLogger(iEvent).length  = timeLogger(iEvent).endTime - timeLogger(iEvent).startTime;  %Get the block duration
    timeLogger(iEvent).isTarget = isTarget(Event_order(iEvent));
    timeLogger(iEvent).response = responses(iEvent);
    % add target or not
    % add response pressed or not
    % what is the response button?
    % consider adding the ending of each sound, atm it's the event (sound +
    % response gap)
    % consider adding WaitSec for ending? 
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
PsychPortAudio('Close',phandle);
myTotalSecs=GetSecs;
Experiment_duration = myTotalSecs - experimentStartTime;

%% Save a mat Log file
% Onsets & durations are saved in seconds.
save(['logFileFull_',SubjName,'.mat']);
save(['logFile_',SubjName,'.mat'], 'names','onsets','durations','ends','targets','responseTime','responseKey','targetTime','Experiment_duration','playTime');

fprintf('Sequence IS OVER!!\n');
%end
