function createSiriSounds

% SoundLevel
soundLevel = 6 ; 

% Sequence
Sequence = {
{'L','R','D','U'}
{'D','L','U','R'}
{'U','D','R','L'}
{'R','U','L','D'}
{'D','R','U','L'}
{'L','U','R','D'}
{'R','L','D','U'}
{'U','D','L','R'}
};

Siri = struct;
% for each sequence
for i=1:length(Sequence)
    
% Get its name and sound level    
Siri(i).name = ['cond',num2str(i),'_',num2str(soundLevel)];
Siri(i).Seq= Sequence{i};        % import the sequence of events

% read the audio file
[Siri(i).Y , Siri(i).FS] = audioread(['cond',num2str(i),'_',num2str(soundLevel),'.wav']);

% Convert the mono-channel to 2 channel and invert the matrix for play in
% psychportaudio
Siri(i).Y = [Siri(i).Y Siri(i).Y]' ;

end

% Save all the voices in a siri.mat file
save(['Siri_',num2str(soundLevel),'.mat'],'Siri')
