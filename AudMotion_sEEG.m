%function AudMotion_sEEG

% Original Script Written by Sam Weiller to localize MT+/V5
% Adapted by M.Rezk to localize MT/MST (Huk,2002)
% Simplify the ALocaliser fmri experiment for ERPs

% simply run the script and press enter instead of specifying the
% SubjectName & provide run# to be savedin the logfile, and provide the
% length trials/duration of exp (options: 1-2-3)


% NOTES:
% when the response is given while the sound is played, it can be
% understood in the logfile, because of the time stamp.

clear all;  %#ok<CLALL>
clc

tic

%% CHANGE ME IF IT'S NEEDED

%adjust the amp according to the participant
% multiply the audio by this value to decrease the volume
new_amp = 0.2; 

%after everything is ready, wait a bit to initiate sound playing loop
Init_pause = 3;

%%
%% set trial or real experiment
% device = 'eeg'; % any sound card, triggers through parallel port
device = 'RME_RCAtrig'; % works with RME sound card and sends one trigger value through RCA cable (trigger box) 
% device = 'trial'; % any sound card, no triggers (parallel port not open)

fprintf('Connected Device is %s \n\n',device);

%% Start me up
% get the subject Name
SubjName = input('\nSubject Name: ','s');
Run = input('\nrun n.: ','s');

% here is prompt a multiverse scenario in witch you can choos n. of trials
% and therefore the length of the experiment
fprintf('\n\n case 1 - 54 trials per condition (Motion & Static) + ~10%% targets (n.12) \n          for ~5 min, to repeat at least 2 times\n')
fprintf('\n case 2 - 40 trials per condition (Motion & Static) + ~9%% targets (n.8) \n          for ~4 min, to repeat at least 3 times\n')
fprintf('\n case 3 - 28 trials per condition (Motion & Static) + ~12%% targets (n.8) \n          for ~3 min, to repeat at least 4 times\n\n')
 
expLength = input('length of th exp. [1 - 2 - 3]: ','s');
fprintf('\n')
if isempty(SubjName)
    SubjName = 'test';
end
if isempty(Run)
    Run=99;
end

fprintf('Auditory ERPs \n\n')

%% Experiment Parametes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
freq = 44100;

audio_config.freq = freq; 

switch str2num(expLength)
    
    case 1
        % number of trials
        numEvents = 120;
        % n of target trials
        numTargets = 12;
    case 2
        numEvents = 88;
        numTargets = 8;
    case 3
        numEvents = 64;
        numTargets = 8;
end                                                       

% creating jitter with uniform distribution around 1 average is 1.5 (after 
%1s sound, 1s min gap and max 2s)
jitter = rand(1,numEvents);        

% CONSIDER MAKING JITTER BALANCED ACROSS CONDITIONS

% a vector of interstimulus intervals for each event
ISI = 1 + jitter;   

DateFormat = 'yyyy_mm_dd_HH_MM';

Filename = fullfile(pwd, 'output', ...
    ['sub-' SubjName, ...
    '_run-' Run, ...
    '_case-n-' expLength, ...
    '_' datestr(now, DateFormat) '.tsv']);

% prepare for the output
% ans 7 means that a directory exist
if exist('output', 'dir') ~= 7 
    mkdir('output');
end

% open a tsv file to write the output
fid = fopen(Filename, 'a');
fprintf(fid, 'SubjID\tExp_trial\tCondition\tSoundfile\tTarget\tTrigger\tISI\tEvent_start\tEvent_end\tEvent_duration\tResponse\tRT\n');  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Experimental Design

% pseudorandomized events order: 2 MOTION + 1 static + 10% of targers
[Event_names, Event_order]= getTrialSeq(numEvents,numTargets,expLength);          

% reassign it in case pseudorandomization provided less trial number
numEvents = length(Event_order); 

soundfiles = {...
    'rms_static_1s',...
    'rms_mot_LR_1s',...
    'rms_mot_RL_1s',...
    'rms_static_2s',...
    'rms_mot_LR_2s',...
    'rms_mot_RL_2s'}; 

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
elseif any(strcmp(device,{'trial','RME_RCAtrig'}))
    % assign number of trails to 15 
%     numEvents = 15;
end

%% InitializePsychAudio;

% load all the sounds & lower the amplitude of the sounds
% lower the amp is crucial for the in-ear headphone set!
for icon = 1:numcondition
    
    chosen_file{icon} = [soundfiles{icon},'.wav'];
    filename = fullfile('stimuli',SubjName,chosen_file{icon}); 
    [SoundData{icon},~]=audioread(filename); 
    SoundData{icon} = SoundData{icon} .* new_amp; 
    SoundData{icon} = SoundData{icon}';
    
end


InitializePsychSound(1);

% open audio port
% if any(strcmp(device,{'trial','eeg'}))  
%    pahandle = PsychPortAudio('Open',[],[],1,freq,2);
% elseif any(strcmp(device,{'RME_RCAtrig'})) 
%     audio_devices = PsychPortAudio('GetDevices'); 
%     dev_idx = find(~cellfun(@isempty, regexpi({audio_devices.DeviceName},'Fireface UC Mac'))); 
%     devID = audio_devices(dev_idx).DeviceIndex; 
% %     dev_n_channels = audio_devices(dev_idx).NrOutputChannels; 
%     dev_n_channels = 4; 
%     pahandle = PsychPortAudio('Open', devID, [], 3, freq, dev_n_channels);% pahandle = 
            %PsychPortAudio('Open' [, deviceid][, mode][, reqlatencyclass][, freq][, channels] ...
            %[, buffersize][, suggestedLatency][, selectchannels][, specialFlags=0]);
%     addpath(genpath('lib')); 
%     sound_vol = PTB_volGUI_RME('pahandle',pahandle,'sound',SoundData{1},'nchan',dev_n_channels,'volume',0.01); 
% 
% end

audio_config.sound =  SoundData{1}; %
audio_config = triggerSend('open', device, audio_config);


fprintf('starting experiment... \n');

%% Experiment Start

% get time point at the beginning of the experiment (machine time)
experimentStartTime = GetSecs();

%initial pause
WaitSecs(Init_pause);

%% Loop starts

% targetTime   = [];

eventOnsets =       zeros(1,numEvents);
eventEnds =         zeros(1,numEvents);
eventDurations =    zeros(1,numEvents);
responses =         zeros(1,numEvents);
playTime =          zeros(1,numEvents);

for iEvent = 1:numEvents
    
    startEvent = GetSecs();
    responseKey  = [];
    responseTime = [];

        
    % get the onset time
    eventOnsets(iEvent)=GetSecs-experimentStartTime;
    % get the condition of the event (motion or static)
    timeLogger(iEvent).condition = condition(Event_order(iEvent));
    % get the name of the event
    timeLogger(iEvent).names = soundfiles(Event_order(iEvent));
    % get the ISI of the event
    timeLogger(iEvent).ISI = ISI(iEvent);                                               
    
    % Load the chosen sound
    Sound = SoundData{Event_order(iEvent)}; 
    
    
    
    
    % fill the buffer 
%     if any(strcmp(device,{'trial','eeg'}))
%         PsychPortAudio('FillBuffer',pahandle,Sound);                        
%     elseif any(strcmp(device,{'RME_RCAtrig'}))
% 
%         trig_pulse = zeros(1, length(Sound)); 
%         trig_pulse(1:round(0.100*freq)) = 1; 
%         s_out = zeros(dev_n_channels, length(Sound)); 
%         s_out(1,:) = Sound(1,:); % left earphone
%         s_out(2,:) = Sound(2,:); % right earphone
%         s_out(3,:) = trig_pulse; % trigger pulse
%         
%         PsychPortAudio('FillBuffer',pahandle, s_out);                        
%     end
    
    audio_config.sound =  SoundData{1};
    audio_config = triggerSend('fillBuffer', device, audio_config);
    
    
    % send the trigger
%     if strcmp(device,'eeg')
%         
%         % >>> consider to add a +10, ask Franci why
% 
%         % assign trigger to which sound will be played     
%         trigger = Event_order(iEvent);   
%         
%         % play the sound
%         playTime(1,iEvent) = PsychPortAudio('Start', pahandle, [],[], 1);
%         
%         % send the trigger 
%         sendparallelbyte(trigger);
%         % wait for 100 ms
%         WaitSecs(0.100); 
%         %reset the parallel port
%         sendparallelbyte(0);
%         
%     else
%         % assign trigger to which sound will be played anyway,it will go in
%         % the outputfile
%         trigger = Event_order(iEvent);   
%         %Play the sound
%         playTime(1,iEvent) = PsychPortAudio('Start', pahandle, [],[],1);
%     end
    
    audio_config = triggerSend('start', device, audio_config);
    playTime(1,iEvent) = audio_config.playTime ;
    % log the start time of the sound
    timeLogger(iEvent).startTime = playTime(1,iEvent) - experimentStartTime; %#ok<*SAGROW>

    
    % wait for the ISI and register the responseKey
    while (GetSecs-(playTime(1,iEvent)+(length(Sound)/freq))) <= (ISI(iEvent))
        
        [keyIsDown, secs, keyCode] = KbCheck(-1);
        
        if keyIsDown
            
            responseKey = KbName(find(keyCode));
            responseTime = secs - experimentStartTime;
            
            % ecs key press - stop playing the sounds//script
            if strcmp(responseKey,'DELETE')==1
                
%                 % If the script is stopped while a sequence is being
%                 % played, it sends trigger 7
%                 PsychPortAudio('Close', pahandle);
%                 
%                 % if sEEG (don't do that in the pc) >>>> CB ?
%                 if strcmp(device,'eeg')
%                     % Is it possible to not hard code the trigger values in
%                     % here and instead have them as variable at the top of
%                     % the script --> this will help Francesca for analysis
%                     % and future us if we want to change those values
%                     % quickly
%                     % Ideally we should also know what each trigger means
%                     % and not have to go and look into getSeqTrials to
%                     % figure it out.
%                     
%                     % triggers code for escape is 7
%                     sendparallelbyte(7)
%                     sendparallelbyte(0)
%                 end

                audio_config = triggerSend('abort', device, audio_config);
                
                return
                
            else
                % this part is only relevant for trigger send to EEG the
                % usual way and not via the sound card
%                 if strcmp(device,'eeg')
%                     % trigger code for any keypress is 20
%                     sendparallelbyte(20);
%                     WaitSecs(0.100); 
%                     sendparallelbyte(0)
%                 end
                [audio_config] = triggerSend('abort', device, audio_config);
            end
            
        end
    end
    
    %calculate timings
    eventEnds(iEvent)=GetSecs-experimentStartTime;
    eventDurations(iEvent)=eventEnds(iEvent)-eventOnsets(iEvent);
      
    % get the total trial duration
    timeLogger(iEvent).length  = eventDurations(iEvent); 
    % get the time for the block end
    timeLogger(iEvent).endTime = eventEnds(iEvent);                                    
    timeLogger(iEvent).responseTime = responseTime;
    timeLogger(iEvent).response = responseKey;
    timeLogger(iEvent).isTarget = isTarget(Event_order(iEvent));
    timeLogger(iEvent).soundcode = trigger;                               
    
    fprintf(fid,'%s\t %d\t %s\t %s\t %d\t %d\t %f\t %f\t %f\t %f\t %s\t %f\n',...
        SubjName, iEvent, string(condition(Event_order(iEvent))), string(soundfiles(Event_order(iEvent))), ...
        isTarget(Event_order(iEvent)), trigger, ISI(iEvent), ...
        timeLogger(iEvent).startTime, eventEnds(iEvent), eventDurations(iEvent), ...
        responseKey, responseTime);
       
    % CONSIDER what happens in case of buttonpress>1
    % CONSIDER adding timeLogger(iEvent).playTime into fprintf (log .tsv
    % file)
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

%% Take the total exp time
% PsychPortAudio('Close',pahandle);
audio_config = triggerSend('close', device, audio_config);
Experiment_duration = GetSecs - experimentStartTime;

%% Save a mat Log file
% Onsets & durations are saved in seconds.
save(fullfile(pwd, 'output', ['logFileFull_', SubjName, '_run-' Run,'_case-n-' expLength,'.mat']));
save(fullfile(pwd, 'output', ['logFile_', SubjName, '_run-' Run,'_case-n-' expLength,'.mat']), ...
    'names', 'onsets', 'durations', 'ends', 'responseTime', ...
    'responseKey', 'Experiment_duration', 'playTime','timeLogger');

fclose(fid);

expTime = toc;

fprintf('\nSequence IS OVER!!\n');
fprintf('\n==================\n\n');

fprintf('\nyou have tested %d trials for STATIC and %d trials for MOTION conditions\n\n', ...
    (numEvents-numTargets)/2, (numEvents-numTargets)/2);

fprintf('\nexp. duration was %f minutes\n\n', expTime/60);


