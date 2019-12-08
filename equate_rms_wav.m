function  equate_rms_wav()

% input the folder with the audio files
file_dir = 'stimuli/test/targets'; % input_lepoulpe %input_earfish

% read the wav file in the target folder
addpath(fullfile(pwd, file_dir));
file_list = dir([file_dir,'/*.wav']);

% select the reference audio file
reference_wav_fn = 'mot_RL_2s.wav';

% select only the audio file that are not rms-ed already and rms them 
for i = 1:size(file_list,1)
    
    if ~contains(file_list(i).name, 'rms')
        
        target_wav_fn = file_list(i).name;
        fprintf('\n\n\n%s\n\n', target_wav_fn)
        runFunction (reference_wav_fn,target_wav_fn,file_dir)
        
    end

end

end

function runFunction(reference_wav_fn,target_wav_fn,file_dir)
%% This Script takes a file (target_wav_fn) and equates its rms with
% another reference audio file (reference_wav_fn) amd gives the equated 
% wav file as an output ('final_wave.wav')

% Get the rms of the original sound
[reference_wav , FS_reference]= audioread(reference_wav_fn); 
rms_reference = rms(reference_wav) ;
disp('rms of the reference wav file')
disp(rms_reference)

% Get the rms for the edited combined sound (static)
[target_wav, FS_target] = audioread(target_wav_fn); 
rms_target = rms(target_wav) ;
disp('rms of the target wav file')
disp(rms_target)

% correct for the rms differences in each channel
final_wave = [ target_wav(:,1)*(rms_reference(1)/rms_target(1)) ...
               target_wav(:,2)*(rms_reference(2)/rms_target(2))] ;
           
% check that the rms of the final is similar to the original           
rms_final = rms(final_wave);
disp('rms of the final wav file')
disp(rms_final)

audiowrite(fullfile(file_dir, ['rms_',target_wav_fn]),final_wave,FS_reference)

%% plot the reference wav and final wav files
figure()
subplot(2,1,1)
plot(reference_wav(:,1),'r')
hold on 
plot(reference_wav(:,2),'b')
title('Reference wav file')

subplot(2,1,2)
plot(final_wave(:,1),'r')
hold on 
plot(final_wave(:,2),'b')
title('Final wav file')

end



