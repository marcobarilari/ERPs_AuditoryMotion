function equate_rms_wav()

addpath(fullfile(pwd,'input_earfish'));

%% 250 MS
reference_wav_fn = 'olivier_pnoise_250ms_Static_center.wav';

target_wav_fn = 'olivier_pnoise_250ms_OS_down.wav';
runFunction (reference_wav_fn,target_wav_fn)

target_wav_fn = 'olivier_pnoise_250ms_OS_left.wav';
runFunction (reference_wav_fn,target_wav_fn)

target_wav_fn = 'olivier_pnoise_250ms_OS_right.wav';
runFunction (reference_wav_fn,target_wav_fn)

target_wav_fn = 'olivier_pnoise_250ms_OS_up.wav';
runFunction (reference_wav_fn,target_wav_fn)

%% 500 ms
target_wav_fn = 'olivier_pnoise_500ms_Static_center.wav';
runFunction (reference_wav_fn,target_wav_fn)

target_wav_fn = 'olivier_pnoise_500ms_OS_down.wav';
runFunction (reference_wav_fn,target_wav_fn)

target_wav_fn = 'olivier_pnoise_500ms_OS_left.wav';
runFunction (reference_wav_fn,target_wav_fn)

target_wav_fn = 'olivier_pnoise_500ms_OS_right.wav';
runFunction (reference_wav_fn,target_wav_fn)

target_wav_fn = 'olivier_pnoise_500ms_OS_up.wav';
runFunction (reference_wav_fn,target_wav_fn)

%% 1000 ms

target_wav_fn = 'olivier_pnoise_1000ms_OS_left.wav';
runFunction (reference_wav_fn,target_wav_fn)

target_wav_fn = 'olivier_pnoise_1000ms_OS_right.wav';
runFunction (reference_wav_fn,target_wav_fn)

target_wav_fn = 'olivier_pnoise_1000ms_Static_center.wav';
runFunction (reference_wav_fn,target_wav_fn)

%% 2000 ms
target_wav_fn = 'olivier_pnoise_2000ms_Static_center.wav';
runFunction (reference_wav_fn,target_wav_fn)

end


function runFunction (reference_wav_fn,target_wav_fn)
%% This Script takes a file (target_wav_fn) and equates its rms with
% another reference audio file (reference_wav_fn) amd gives the equated 
% wav file as an output ('final_wave.wav')

%reference_wav_fn = 'R_L.wav';
%target_wav_fn = 'L_R.wav';

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
%wavwrite(new_wave,'new_wave.wav')
%audiowrite(target_wav_fn,final_wave,FS_reference)
%wavwrite(final_wave,FS_reference,16,['rms_',target_wav_fn])
audiowrite(['rms_',target_wav_fn],final_wave,FS_reference)
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


