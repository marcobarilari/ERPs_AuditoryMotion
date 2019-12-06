function [audio_config] = triggerSend(action, device, audio_config)
% a wrapper function to interact with psychport audio in case you are using a Fireface UC Mac / RME_RCAtrig
%       external sound card.
%
% usage: 
%   [audio_config] = triggerSend('open', device, audio_config)
%       Will open PsychPortAudio and return audio_config with the relevant
%       field that are needed later (pahandle, dev_n_channels, devID). Will also set volume of trigger 
%       channel when using the external sound card.
%
%   [audio_config] = triggerSend('fillBuffer', device, audio_config)
%       Fills the audio buffer with sound only (classic EEG) or with sound + trigger (Fireface UC Mac) to
%       be sent via the external soundcard.
% 
% input / output:
%   device: a string that can be:
%         - 'trial'  --> to run on a PC by itself not connected to EEG or
%                           external soundcard.
%         - 'eeg'  --> to run when doing EEG using the regular triggers 
%         - 'RME_RCAtrig' --> to run when doing EEG using trigges via external sound card 
%
%   audio_config: a structure that can contain the following fields
%         - freq  --> the sound sampling frequency to use
%         - sound  --> the sound sampling frequency to use
%         - dev_n_channels  --> number of audio channels used
%         - devID  --> audio device ID (when using the external sound card)
%         - pahandle --> handle returned by psych port audio when it is
%               being opened. To use if you want to interac with it further



%% Parameters
% set the volume at which to play the trigger so it can actualy be detected
volume = 0.01;

% number of audio channel used
dev_n_channels = 4;

% trigger values for regular EEG
trigger.start = 1;
trigger.abort = 2;
trigger.resp = 3;

% wait time before sending trigger and resetting it
trigger_delay = 0.1;


%% Get input
freq = audio_config.freq;
sound = audio_config.sound; 

% NEED TO CHECK INPUTS
% dimension of sound??



switch action
    
    case 'open'
        
        
        if any(strcmp(device,{'trial','eeg'}))
            
            dev_n_channels = [];
            
            pahandle = PsychPortAudio('Open', [], [], 1, freq, 2);
            
            audio_config.pahandle = pahandle;
            audio_config.dev_n_channels = dev_n_channels;
          
            
        elseif any(strcmp(device,{'RME_RCAtrig'}))
            
            % add the libraries necessary for the sound card
            addpath(genpath(fullfile(pwd, 'lib')));
            
            % ask PTB to identify all the audio devices and we select the
            % one that has the name of the sound card we want to use
            audio_devices = PsychPortAudio('GetDevices');
            dev_idx = find(~cellfun(@isempty, regexpi({audio_devices.DeviceName},'Fireface UC Mac')));
            devID = audio_devices(dev_idx).DeviceIndex; %#ok<FNDSB>
            
            
            % then we open the psychoport audio using this device and
            % setting the number of channels
            
            % dev_n_channels = audio_devices(dev_idx).NrOutputChannels;
            
            % pahandle = PsychPortAudio('Open' [, deviceid][, mode][, reqlatencyclass][, freq] ...
            %       [, channels][, buffersize][, suggestedLatency][, selectchannels][, specialFlags=0]);
            pahandle = PsychPortAudio('Open', devID, [], 3, freq, dev_n_channels);
            
            
            % then we set the volume on that channel
            sound_vol = PTB_volGUI_RME(...
                'pahandle', pahandle,...
                'sound', sound,...
                'nchan', dev_n_channels,...
                'volume', volume);
            
            audio_config.pahandle = pahandle;
            audio_config.dev_n_channels = dev_n_channels;
            audio_config.devID = devID;
            
        end
        
        
        
    case 'fillBuffer'

        pahandle = audio_config.pahandle;
        dev_n_channels = audio_config.dev_n_channels;
        
        if any(strcmp(device,{'trial','eeg'}))
            
            PsychPortAudio('FillBuffer', pahandle, sound);
            
        elseif any(strcmp(device,{'RME_RCAtrig'}))
            
            trig_pulse = zeros(1, length(sound));
            trig_pulse( 1:round(0.100*freq) ) = 1;
            
            % we create a sound with 3 channels and the thirs one actually
            % contains the squared pulse trigger
            s_out = zeros(dev_n_channels, length(sound));
            
            % left earphone
            s_out(1,:) = sound(1,:); 
            % right earphone
            s_out(2,:) = sound(2,:); 
            % trigger pulse
            s_out(3,:) = trig_pulse; 
            
            PsychPortAudio('FillBuffer', pahandle, s_out);
            
        end
        
    case 'start'
        
        % WORK IN PROGRESS
        
%         pahandle = audio_config.pahandle;
%         
%         playTime(1,iEvent) = PsychPortAudio('Start', pahandle, [],[], 1);
%         
%         if any(strcmp(device,{'eeg'}))
%             % send the trigger 
%             sendparallelbyte(trigger.start);
%             % wait before resetting trigger
%             WaitSecs(trigger_delay); 
%             %reset the parallel port
%             sendparallelbyte(0);
%         end
        
    case 'abort'
        
        % WORK IN PROGRESS
        
%         pahandle = audio_config.pahandle;
%         
%         PsychPortAudio('Close', pahandle);
%         
%         if strcmp(device,'eeg')
%             % send the abort trigger
%             sendparallelbyte(trigger.abort)
%             % reset the parallel port
%             sendparallelbyte(0)
%         end
        
    case 'resp' 
        
        % WORK IN PROGRESS
        
%         if strcmp(device,'eeg')
%             % send the response trigger
%             sendparallelbyte(trigger.resp);
%             WaitSecs(trigger_delay);
%             % reset the parallel port
%             sendparallelbyte(0)
%         end
        
end


end