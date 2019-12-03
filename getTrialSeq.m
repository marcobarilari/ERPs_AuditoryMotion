function [trial_seq_names,trial_seq] = getTrialSeq(numTrials, percTarget)

% function to create the randomization of all the conditions in the ERP -
%motion experiemnt
%
% with numTrails and percTarget it calculates the number of trials per
% condition

% number assigned order:
% static 1
% mot_LRRL 2
% mot_RLLR 3
% Static_T 4
% mot_LRRL_T 5
% mot_RLLR_T 6

static = (numTrials*(100-percTarget))/100/2;
mot_LRRL = ((numTrials*(100-percTarget))/100)/4;
mot_RLLR = ((numTrials*(100-percTarget))/100)/4;
static_T = ((numTrials*(percTarget))/100)/2;
mot_LRRL_T = ((numTrials*(percTarget))/100)/4;
mot_RLLR_T = ((numTrials*(percTarget))/100)/4;

trial_seq = [ repmat(1,1,static), repmat(2,1,mot_LRRL), ...
    repmat(3,1,mot_RLLR), repmat(4,1,static_T), ...
    repmat(5,1,mot_LRRL_T), repmat(6,1,mot_RLLR_T)];

trial_seq_names = Shuffle(trial_seq);
% force a rule of targets will not show up all in a row.
%e.g. by diciding it into 4 parts and inserting the targets

% trial_seq_names = [ repmat({'Static'},1,static), repmat({'mot_LRRL'},1,mot_LRRL), ...
%     repmat({'mot_RLLR'},1,mot_RLLR), repmat({'Static_T'},1,static_T), ...
%     repmat({'mot_LRRL_T'},1,mot_LRRL_T), repmat({'mot_RLLR_T'},1,mot_RLLR_T) ];





end