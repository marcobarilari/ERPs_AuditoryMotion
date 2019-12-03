function [soundData, FS, phandle]=loadAudioFiles(AudiofilesFolder,subjectName)

% Intialize PsychPortAudio
InitializePsychSound(1);


% Load Left to Right Motion
fileName=fullfile(AudiofilesFolder,[subjectName,'_R.wav']);
[soundData.direction_0 , freq_0]=audioread(fileName);
soundData.direction_0 = soundData.direction_0';

% Load Right to Left Motion
fileName=fullfile(AudiofilesFolder,[subjectName,'_L.wav']);
[soundData.direction_180 , freq_180]=audioread(fileName);
soundData.direction_180 = soundData.direction_180';

% Load upward Motion
fileName=fullfile(AudiofilesFolder,[subjectName,'_U.wav']);
[soundData.direction_90 , freq_90]=audioread(fileName);
soundData.direction_90 = soundData.direction_90';

% Load downward Motion
fileName=fullfile(AudiofilesFolder,[subjectName,'_D.wav']);
[soundData.direction_270 , freq_270]=audioread(fileName);
soundData.direction_270 = soundData.direction_270';

%% Targets
% Load Left to Right Motion - Target
fileName=fullfile(AudiofilesFolder,[subjectName,'_R_T.wav']);
[soundData.Tdirection_0 , freq_T_0]=audioread(fileName);
soundData.Tdirection_0 = soundData.Tdirection_0';

% Load Right to Left Motion - Target
fileName=fullfile(AudiofilesFolder,[subjectName,'_L_T.wav']);
[soundData.Tdirection_180 , freq_T_180]=audioread(fileName);
soundData.Tdirection_180 = soundData.Tdirection_180';

% Load upward Motion - Target
fileName=fullfile(AudiofilesFolder,[subjectName,'_U_T.wav']);
[soundData.Tdirection_90 , freq_T_90]=audioread(fileName);
soundData.Tdirection_90 = soundData.Tdirection_90';

% Load downward Motion - Target
fileName=fullfile(AudiofilesFolder,[subjectName,'_D_T.wav']);
[soundData.Tdirection_270 , freq_T_270]=audioread(fileName);
soundData.Tdirection_270 = soundData.Tdirection_270';


%%

% check frequency of all stimuli are the same
%unique([freq_0 freq_90 freq_180 freq_270 freq_T_0 freq_T_90 freq_T_180 freq_T_270])

if length(unique([freq_0 freq_90 freq_180 freq_270 freq_T_0 freq_T_90 freq_T_180 freq_T_270]))>1
    error('Check the frequency of the audiofiles')
end

FS = freq_0 ; 

phandle = PsychPortAudio('Open',[],[],1,FS,2);

fprintf(' audio files loaded (not rms). \n\n')
%PsychPortAudio('FillBuffer',phandle,soundData.direction_0(:,1:1000));
%playTime = PsychPortAudio('Start',phandle,[],[],[]);
