
AudiofilesFolder= pwd;

% Load Left to Right Motion
fileName=fullfile(AudiofilesFolder,'rms_R.wav');
[soundData.direction_0 , freq_0]=audioread(fileName);
soundData.direction_0 = soundData.direction_0';

% Load Right to Left Motion
fileName=fullfile(AudiofilesFolder,'rms_L.wav');
[soundData.direction_180 , freq_180]=audioread(fileName);
soundData.direction_180 = soundData.direction_180';

% Load upward Motion
fileName=fullfile(AudiofilesFolder,'rms_U.wav');
[soundData.direction_90 , freq_90]=audioread(fileName);
soundData.direction_90 = soundData.direction_90';

% Load downward Motion
fileName=fullfile(AudiofilesFolder,'rms_D.wav');
[soundData.direction_270 , freq_270]=audioread(fileName);
soundData.direction_270 = soundData.direction_270';

%% Targets
% Load Left to Right Motion - Target
fileName=fullfile(AudiofilesFolder,'rms_R_T.wav');
[soundData.Tdirection_0 , freq_T_0]=audioread(fileName);
soundData.Tdirection_0 = soundData.Tdirection_0';

% Load Right to Left Motion - Target
fileName=fullfile(AudiofilesFolder,'rms_L_T.wav');
[soundData.Tdirection_180 , freq_T_180]=audioread(fileName);
soundData.Tdirection_180 = soundData.Tdirection_180';

% Load upward Motion - Target
fileName=fullfile(AudiofilesFolder,'rms_U_T.wav');
[soundData.Tdirection_90 , freq_T_90]=audioread(fileName);
soundData.Tdirection_90 = soundData.Tdirection_90';

% Load downward Motion - Target
fileName=fullfile(AudiofilesFolder,'rms_D_T.wav');
[soundData.Tdirection_270 , freq_T_270]=audioread(fileName);
soundData.Tdirection_270 = soundData.Tdirection_270';




soundLength(1) = length(soundData.direction_0) ;
soundLength(2) = length(soundData.direction_90) ;
soundLength(3) = length(soundData.direction_180) ;
soundLength(4) = length(soundData.direction_270) ;

soundLengthT(1) = length(soundData.Tdirection_0) ;
soundLengthT(2) = length(soundData.Tdirection_90) ;
soundLengthT(3) = length(soundData.Tdirection_180) ;
soundLengthT(4) = length(soundData.Tdirection_270) ;

% Check if sound events have the same duration 
fprintf('\n\n')
if length(unique(soundLength))>1
    error('Event Sound Files do not have the same length')
else
    fprintf('Event Sound lengths are equal. Duration: %0.4f Secs. \n\n',length(soundData.direction_0)/freq_0)
end

% Check if sound events have the same duration 
if length(unique(soundLengthT))>1
    error('Target Sound Files do not have the same length')
else
    fprintf('Target Sound lengths are equal. Duration: %0.4f Secs. \n\n',length(soundData.Tdirection_0)/freq_0)
end
