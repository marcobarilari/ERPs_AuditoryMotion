function playedAudio = playAudio(Cfg,phandle,soundData,iEventSpeed,iEventDirection)


if iEventSpeed == Cfg.speedTarget                         % check if its a target event
    playedAudio = eval(['soundData.Tdirection_',num2str(iEventDirection)]);
else
    playedAudio = eval(['soundData.direction_',num2str(iEventDirection)]);
end
PsychPortAudio('FillBuffer',phandle,playedAudio);        % prepare right wave file

PsychPortAudio('Start',phandle,[],[],[]);

end
