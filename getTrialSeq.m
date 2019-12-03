function [trial_seq] = getTrialSeq(numTrials, percTarget)

% function to create the randomization of all the conditions in the ERP -
%motion experiemnt
%
% with numTrails and percTarget it calculates the number of trials per
% condition

static = (numTrials*(100-percTarget))/100;

mot_LRRL = ((numTrials*(100-percTarget))/100)/2;

mot_RLLR = ((numTrials*(100-percTarget))/100)/2;

static_T = ((numTrials*(percTarget))/100)/2;

mot_LRRL_T = ((numTrials*(percTarget))/100)/4;

mot_RLLR_T = ((numTrials*(percTarget))/100)/4;

trial_seq = [ repmat({'static'},1,static), repmat({'mot_LRRL'},1,mot_LRRL), ...
    repmat({'mot_RLLR'},1,mot_RLLR), repmat({'static_T'},1,static_T), ...
    repmat({'mot_LRRL_T'},1,mot_LRRL_T), repmat({'mot_RLLR_T'},1,mot_RLLR_T) ];

trial_seq = Shuffle(trial_seq);

end