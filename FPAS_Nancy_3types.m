%% FPAS_Nancy
% Fast auditory periodic stimulation, Francesca M Barbero 08/10/2019
clc
clear
PsychPortAudio('Close');


%% Parameters
SubjName = 2; % subject code 

Run = 1;

% Sequences types to be played: 1-standard, 2-scrambled, 6-harmonic
seqType = [1 2 6]; 

codeSeq = {'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L'};

% Number of repetition for each sequence type
nRep = 2; 

% Folder where the sequences are contained
seqDir = fullfile('D:', 'Nancy_Battery', '3_AUDITIF','Sequences','AttentionalTarget');

device = 'RME_RCAtrig'; % 'trial' 'eeg'

FS = 44100; % Sampling frequency of the sounds


%% Create dir
% Create a folder for the subject code to save a text file with the order
% of the sequences presented. If the folder of the subject code already
% exists, it stops the script
if exist((sprintf('sub-%03d', SubjName)),'dir')==7
    warning('Folder already exist, stopping the script')
    return 
else
    mkdir(sprintf('sub-%03d', SubjName));
end

% Create a text file to save order sequence presentation
txtFname = fullfile(sprintf('sub-%03d', SubjName), sprintf('log_sub-%03d_list.tsv', SubjName) );
fidwrit = fopen(txtFname, 'wt');
% add headers to log file
fprintf(fidwrit, 'onset\tduration\ttrial_type\n');


%% Loading sequences from defined folders
for st = 1:length(seqType) %sequence type
    for cs = 1: nRep
        tyFo = sprintf('Type%d',seqType(st)); % type folder
        suFo = sprintf('SUB%03d',SubjName); % subject folder
        noFi = sprintf('Type%d_SUB%03d_%s.wav', seqType(st), SubjName,codeSeq{cs} ); % name of individual sequence
        
        % save a structure called seq{seqType,codeSeq} 
        seq{st,cs}.name = noFi; %#ok<*SAGROW>
        [seq{st,cs}.audio, seq{st,cs}.FS] = audioread(fullfile(seqDir,tyFo,suFo,noFi));
    end
end


%% Initialize

rand('seed',sum(100*clock));

% Make sure no keys are disabled
DisableKeysForKbCheck([]);

% 'reallyneedlowlatency' flag set to one to push really hard for low latency.
InitializePsychSound(1) 

% load and add test sound
audio_config.sound = sound;
audio_config.freq = FS; 

% open psychport audio
audio_config = triggerSend('open', device, audio_config);

% Open parallel port if we use eeg for triggers
triggerSend('open', device, audio_config);


%% Main loop
% Loop over the number of repetition of each sound, so that each sequence type is presented at least one
for iRep = 1:nRep 
    
    % (Pseudo)randomise order of presentation of the sequences (each
    % sequence type is presented once, then the randomisation is done again
    orderseq = randperm(size(seqType,2)); 
    
    for j = 1:size(seq,1) % Loop over the different sequence types
        
        
        %% Wait space bar press
        % key code to start a sequence: 5
        keyCodeStart = KbName('5%');
        abletostart = false;
        keyIsDown = 0;
        
        while ~abletostart 
            [keyIsDown, pressedSecs, keyCode] = KbCheck(-1);
            if keyIsDown
                if find(keyCode)==keyCodeStart
                    abletostart = true;
                    % break;
                elseif find(keyCode)== KbName('DELETE') %% Put escape here
                    PsychPortAudio('Close');
                    sca
                    return
                end
            end
        end

        %% Fill the audio playback buffer with audio data, doubled: stereo
        sound = seq{orderseq(j),iRep}.audio;
        sound = [sound'; sound'];
        audio_config.sound = sound;
        
        audio_config = triggerSend('fillBuffer', device, audio_config);
        
        audio_config = triggerSend('start', device, audio_config);
        
        if iRep==1
            experimentStartTime = audio_config.playTime;
        end
        
        % Check if the audio is being played or not
        status = PsychPortAudio('GetStatus', pahandle); 
        % While the audio is being played, check keyboard for attentional
        % task (space bar) or for stopping the script (tab)%%%%%%%%%%%%%%
        % change to escape
        while status.Active==1
            status = PsychPortAudio('GetStatus', pahandle);
            [keyIsDown, pressedSecs, keyCode] = KbCheck(-1);
            
            if keyIsDown
                if find(keyCode)== KbName('DELETE') %% PUT ESCAPE HERE
                    
                    % If the script is stopped while a sequence is being
                    % played, close psychport audio and send trigger
                    audio_config = triggerSend('start', device, audio_config);
                    return
                elseif find(keyCode)== KbName('space')
                    
                    % If space bar is pressed (attention task), trigger 5
                    % is sent
%                     sendparallelbyte(5); 
                    
                    while keyIsDown % Waits for space key to be released to continue
                        [keyIsDown, pressedSecs, keyCode] = KbCheck(-1);
                    end
                    
%                     sendparallelbyte(0)
                end
            end
            
        end
     
%         sendparallelbyte(trigCode+20);
%         sendparallelbyte(0);


        % Write to log file
        iDuration = GetSecs - audio_config.playTime;
        iOnset = audio_config.playTime - experimentStartTime;
        iCondition = seq{orderseq(j),iRep}.name;
        
        line = sprintf('%f\t%f\t%iCondition\n', iOnset, iDuration, iCondition);


        % At the end of the sequence, end sequence is displayed on the
        % screen. After 5 seconds the next word appears and it is possible
        % to start a new sequence by pressing 5
        disp('end sequence');
        WaitSecs(5);
        % sendparallelbyte(0);
        disp('next');
        
    end
end

fclose(fidwrit);

%% At the end of the experiment:
PsychPortAudio('Close');
sca


% [ t, table_header ] = make_events(SubjName, task_id, Run, onsets, durations, condition, ...
%     names, ...
%     target, ...
%     Events_order, ...
%     isi, ...
%     eventEnd, ...
%     response, ...
%     responseTime);