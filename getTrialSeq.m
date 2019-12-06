function [trial_seq_names,trial_seq] = getTrialSeq(numEvents,numTargets,expLength)

% function to create the randomization of all the conditions in the ERP -
%motion experiemnt
%
% with numTrails and percTarget it calculates the number of trials per
% condition
%
% outputs the trial sequence with numbers (trial_seq) or with names (trial_seq_names)
%
% number assigned order:
% 1     static
% 2     mot_LRRL
% 3     mot_RLLR
% 4     Static_T
% 5     mot_LRRL_T
% 6     mot_RLLR_T

expLength = str2num(expLength); %#ok<ST2NM>

switch expLength
    
    case 1
        
        nChunks = 3;
        
        numEvents = numEvents/nChunks;
        
        numTargets = numTargets/nChunks;
        
        trial_seq = pseudorand(numEvents, numTargets, nChunks, expLength);
        
    otherwise
        
        nChunks = 2;
        
        numEvents = numEvents/nChunks;
        
        numTargets = numTargets/nChunks;
        
        trial_seq = pseudorand(numEvents, numTargets, nChunks, expLength);
        
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

function trial_seq = pseudorand(numEvents, numTargets, nChunks, expLength)

% calculate how many trials per condition dividing them in 3 chunks to help
% even randomization across experiment per condition

static = (numEvents-numTargets)/2;
mot_LRRL = (numEvents-numTargets)/4;
mot_RLLR = (numEvents-numTargets)/4;
static_T = numTargets/2;
mot_LRRL_T = numTargets/4;
mot_RLLR_T = numTargets/4;

% create the three chunks of condition and randomize them and check that:
% 1 - the target is not in the first trial
% 2 - two target are not consecutive
% 3 - there are no more them 3 same trials consecutive (less than that is impossible)

d = 1; % counter for trial number

while d < numEvents*nChunks-2
    
    % create a sequence of trials that contains 1 thirs of all the trials
    trial_seq = [ ...
        repmat(ones,1,static),  repmat(2,1,mot_LRRL),   repmat(3,1,mot_RLLR), ...
        repmat(4,1,static_T),   repmat(5,1,mot_LRRL_T), repmat(6,1,mot_RLLR_T)];
    
    switch expLength
        
        case 1
            
            % we shuffle 3 times each chunck and concatenate them
            trial_seq = [ Shuffle(trial_seq), Shuffle(trial_seq), Shuffle(trial_seq) ];
            
        otherwise
            
            % we shuffle 2 times each chunck and concatenate them
            trial_seq = [ Shuffle(trial_seq), Shuffle(trial_seq) ];
            
    end
    
    % scan through the trial sequence and checks all the conditions
    while d < length(trial_seq)-2
        
        if d == 1 && trial_seq(d) > 3 % no targets in the first trial
            d = 1;
            break
        elseif trial_seq(d) > 3 && trial_seq(d+1) > 3 % avoid 2 consecutive targets
            d = 1;
            break
            % avoid series 3 times the same conditions
        elseif trial_seq(d) ==  trial_seq(d+1) && trial_seq(d+1) ==  trial_seq(d+2) && trial_seq(d+2) ==  trial_seq(d+3)
            d = 1;
            break
        else
            d = d+1;
        end
    end
end

end