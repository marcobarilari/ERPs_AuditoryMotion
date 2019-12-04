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

% calculate how many trials per condition dividing them in 3 chunks to help
% even randomization across experiment per condition
numTrials = numTrials/3;

static = (numTrials*(100-percTarget))/100/2;
mot_LRRL = ((numTrials*(100-percTarget))/100)/4;
mot_RLLR = ((numTrials*(100-percTarget))/100)/4;
static_T = ((numTrials*(percTarget))/100)/2;
mot_LRRL_T = ((numTrials*(percTarget))/100)/4;
mot_RLLR_T = ((numTrials*(percTarget))/100)/4;

% create the three chunks of condition and randomize them and check that: 
% 1 - the target is not in the first trial
% 2 - two target are not consecutive
% 3 - there are no more them 3 same trials consecutive (less than that is impossible)

d = 1;

while d < numTrials*3-2
    
    trial_seq = [ repmat(ones,1,static), repmat(2,1,mot_LRRL), ...
        repmat(3,1,mot_RLLR), repmat(4,1,static_T), ...
        repmat(5,1,mot_LRRL_T), repmat(6,1,mot_RLLR_T)];
    
    trial_seq = [ Shuffle(trial_seq), Shuffle(trial_seq), Shuffle(trial_seq) ];
   
    while d < length(trial_seq)-2
        
        if d == 1 && trial_seq(d) > 3
            d = 1;
            break
        elseif trial_seq(d) > 3 && trial_seq(d+1) > 3
            d = 1;
            break
        elseif trial_seq(d) ==  trial_seq(d+1) && trial_seq(d+1) ==  trial_seq(d+2) && trial_seq(d+2) ==  trial_seq(d+3)
            d = 1;
            break
        else
            d = d+1;
        end
    end
end

% rename the numbers with condition name
trial_seq_names = {};
for i = 1:length(trial_seq)
    trial_seq_names{end+1} = num2str(trial_seq(i)); %#ok<AGROW>
end

trial_seq_names(strcmpi(trial_seq_names,'1')) = {'static'};
trial_seq_names(strcmpi(trial_seq_names,'2')) = {'mot_LRRL'};
trial_seq_names(strcmpi(trial_seq_names,'3')) = {'mot_RLLR'};
trial_seq_names(strcmpi(trial_seq_names,'4')) = {'static_T'};
trial_seq_names(strcmpi(trial_seq_names,'5')) = {'mot_LRRL_T'};
trial_seq_names(strcmpi(trial_seq_names,'6')) = {'mot_RLLR_T'};

end