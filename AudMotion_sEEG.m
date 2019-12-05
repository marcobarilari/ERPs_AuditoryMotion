%function AudMotion_sEEG

% Original Script Written by Sam Weiller to localize MT+/V5
% Adapted by M.Rezk to localize MT/MST (Huk,2002)
% Simplify the ALocaliser fmri experiment for ERPs

% simply run the script and press enter instead of specifying the
% SubjectName

clear all;  %#ok<CLALL>
clc

tic

%% set trial or real experiment
% device = 'eeg';
device = 'trial';

fprintf('Connected Device is %s \n\n',device);

%% Start me up
% get the subject Name
SubjName = input('Subject Name: ','s');
Run = input('run n.: ','s');

% here is prompt a multiverse scenario in witch you can choos n. of trials
% and therefore the length of the experiment
fprintf('\n\n case 1 - 54 trials per condition (Motion & Static) + ~10%% targets (n.12) for ~5 min, to repeat at least 2 times\n')
fprintf('\n case 2 - 40 trials per condition (Motion & Static) + ~9%% targets (n.8) for ~4 min, to repeat at least 3 times\n')
fprintf('\n case 3 - 28 trials per condition (Motion & Static) + ~12%% targets (n.8) for ~3 min, to repeat at least 4 times\n\n')

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
Init_pause = 0;
freq = 44100;

% >>> why we need them?

% number of trials
numEvents = 96;

% percentage of trials as target;                                                            
%percentTrials = 10;

% correspond to 8.3333333% of the total n of trials
numTargets = 8;                                                            

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
[Event_names, Event_order]= getTrialSeq(expLength);          

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
    % assign number of trails to 15 
%     numEvents = 15;
end

%% InitializePsychAudio;
InitializePsychSound(1);

% open audio port
pahandle = PsychPortAudio('Open',[],[],1,freq,2);

% load all the sounds
for icon = 1:numcondition
    
    chosen_file{icon} = [soundfiles{icon},'.wav'];
    filename = fullfile('stimuli',SubjName,chosen_file{icon}); 
    [SoundData{icon},~]=audioread(filename);
    SoundData{icon} = SoundData{icon}';
    
end

fprintf('starting experiment... \n');

%% Experiment Start

% get time point at the beginning of the experiment (machine time)
experimentStartTime = GetSecs();

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

    % get the start time of the event
    timeLogger(iEvent).startTime = GetSecs - experimentStartTime; %#ok<*SAGROW>
    % get the condition of the event (motion or static)
    timeLogger(iEvent).condition = condition(Event_order(iEvent));
    % get the name of the event
    timeLogger(iEvent).names = soundfiles(Event_order(iEvent));
    % get the ISI of the event
    timeLogger(iEvent).ISI = ISI(iEvent);                                               
    
    % Load the chosen sound
    Sound = SoundData{Event_order(iEvent)};  
    
    % fill the buffer 
    PsychPortAudio('FillBuffer',pahandle,Sound);                        
    
    % send the trigger
    if strcmp(device,'eeg')
        
        % >>> consider to add a +10, ask Franci why

        % assign trigger to which sound will be played     
        trigger = Event_order(iEvent);   
        sendparallelbyte(trigger);
        
        % play the sound
        playTime(1,iEvent) = PsychPortAudio('Start', pahandle, [],[],1,startEvent+(length(Sound)/freq));
        
        %reset the parallel port
        sendparallelbyte(0);
        
    else
        
        % assign trigger to which sound will be played anyway,it will go in
        % the outputfile
        trigger = Event_order(iEvent);   
        
        % get the onset time
        eventOnsets(iEvent)=GetSecs-experimentStartTime;
        
        %Play the sound
        playTime(1,iEvent) = PsychPortAudio('Start', pahandle, [],[],1,startEvent+(length(Sound)/freq));
        
    end
    
    % wait for the ISI and register the responseKey
    while (GetSecs-(playTime(1,iEvent)+(length(Sound)/freq))) <= (ISI(iEvent))
        
        [keyIsDown, secs, keyCode] = KbCheck(-1);
        
        if keyIsDown
            
            responseKey = KbName(find(keyCode));
            responseTime = secs - experimentStartTime;
            
            % ecs key press - stop playing the sounds//script
            if strcmp(responseKey,'ESCAPE')==1
                
                % If the script is stopped while a sequence is being
                % played, it sends trigger 7
                PsychPortAudio('Close', pahandle);
                
                % if sEEG (don't do that in the pc)
                if strcmp(device,'eeg') 
                    
                    % triggers code for escape is 30 >>> ?
                    sendparallelbyte(7)
                    sendparallelbyte(0)
                end
                
                return
                
            end
        end
    end
    
    eventEnds(iEvent)=GetSecs-experimentStartTime;
    eventDurations(iEvent)=eventEnds(iEvent)-eventOnsets(iEvent);
      
    % timeLogger(iEvent).length  = timeLogger(iEvent).endTime - timeLogger(iEvent).startTime;  %Get the total trial duration
    % get the total trial duration
    timeLogger(iEvent).length  = eventDurations(iEvent); 
    % get the time for the block end
    timeLogger(iEvent).endTime = eventEnds(iEvent);                                    
    timeLogger(iEvent).responseTime = responseTime;
    timeLogger(iEvent).response = responseKey;
    timeLogger(iEvent).isTarget = isTarget(Event_order(iEvent));
    timeLogger(iEvent).whichtrigger = trigger;                               
    
    fprintf(fid,'%s\t %d\t %s\t %s\t %d\t %d\t %f\t %f\t %f\t %f\t %s\t %f\n',...
        SubjName, iEvent, string(condition(Event_order(iEvent))), string(soundfiles(Event_order(iEvent))), ...
        isTarget(Event_order(iEvent)), trigger, ISI(iEvent), ...
        timeLogger(iEvent).startTime, eventEnds(iEvent), eventDurations(iEvent), ...
        responseKey, responseTime);
       
    % consider adding WaitSec for ending?
    % what would happen if esc key pressed? the logfile will be saved? 
    % >>> NO, I added the tsv file so that in case of escape or crash we
    % have the data anyway
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

%% Take the total exp time
PsychPortAudio('Close',pahandle);
Experiment_duration = GetSecs - experimentStartTime;

%% Save a mat Log file
% Onsets & durations are saved in seconds.
save(fullfile(pwd, 'output', ['logFileFull_', SubjName, '_run-' Run,'_case-n-' expLength,'.mat']));
save(fullfile(pwd, 'output', ['logFile_', SubjName, '_run-' Run,'_case-n-' expLength,'.mat']), ...
    'names', 'onsets', 'durations', 'ends', 'responseTime', ...
    'responseKey', 'Experiment_duration', 'playTime');

fclose(fid);

expTime = toc;

fprintf('\nSequence IS OVER!!\n');
fprintf('\n==================\n\n');

fprintf('\nyou have tested %d trials for STATIC and %d trials for MOTION conditions\n\n', ...
    (numEvents*(100-percentTrials))/100/2, (numEvents*(100-percentTrials))/100/2);

fprintf('\nexp. duration was %f minutes\n\n', expTime/60);


