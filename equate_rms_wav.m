function  equate_rms_wav()

% input the folder with the audio files
file_dir = '../../../Downloads/sEEG_experiments/SpeechTracking/combined/'; % 'stimuli/test/targets'

% read the wav file in the target folder
addpath(fullfile(pwd, file_dir));
file_list = dir([file_dir,'/*.wav']);


stereo = 0; %set it to 1 if the .wav files are stereo
% select the reference audio file
reference_wav_fn = 'TR_mono_Orwell1984_11-31_12-22.wav';

% select only the audio file that are not rms-ed already and rms them 
for i = 1:size(file_list,1)
    
    if ~contains(file_list(i).name, 'rms')
        
        target_wav_fn = file_list(i).name;
        fprintf('\n\n\n%s\n\n', target_wav_fn)
        runFunction (reference_wav_fn,target_wav_fn,file_dir,stereo)
        
    end

end

end

function runFunction(reference_wav_fn,target_wav_fn,file_dir,stereo)
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
if stereo
    final_wave = [ target_wav(:,1)*(rms_reference(1)/rms_target(1)) ...
        target_wav(:,2)*(rms_reference(2)/rms_target(2))] ;
else
    final_wave = [ target_wav(:,1)*(rms_reference(1)/rms_target(1))] ;
end
           
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
if stereo
    plot(reference_wav(:,2),'b')
end
title('Reference wav file')

subplot(2,1,2)
plot(final_wave(:,1),'r')
hold on 
if stereo
    plot(final_wave(:,2),'b')
end
title('Final wav file')

end



