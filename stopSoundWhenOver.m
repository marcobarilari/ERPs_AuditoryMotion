function stopSoundWhenOver(audio_config)
status = PsychPortAudio('GetStatus', audio_config.pahandle);
if ~status.Active
    PsychPortAudio('Stop', audio_config.pahandle);
end
end