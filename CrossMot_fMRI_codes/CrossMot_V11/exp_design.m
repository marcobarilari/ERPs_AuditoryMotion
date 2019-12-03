function [directions, speeds,modalities,fixationTargets] = exp_design(Cfg)


% if Trial set the trial Cfg
if nargin<1
    Cfg = trial_Cfg();
    fprintf('\n\n###################################\n')
    fprintf('This is a trial experiment design\n')
    fprintf('###################################\n\n')
end

%% Assign variables
possibleModalities = Cfg.possibleModalities;
possibleDirections = Cfg.possibleDirections;    % possible motion angles  (-1 is for static)
names               = Cfg.names;                  % 0= Right   90= Up    180= Left    270=down
numRepetitions      = Cfg.numRepetitions;
speedEvent          = Cfg.speedEvent;
speedTarget         = Cfg.speedTarget;
numEventsPerBlock   = Cfg.numEventsPerBlock;
numTargetPerBlock   = Cfg.numTargetPerBlock;
numFixationTargets  = Cfg.numFixationTargets;
displayFigs = 0;

%allModalities={'Visual','Auditory'};
%numModalities = length(allModalities);
%% Experimental Design 

numDirections = length(possibleDirections);       % Get the number of directions present

% get balanced randomized blocks of different directions
repeat = 1;
while repeat > 0 
     
    directions= [] ;
    repeat=[];
    
    %[directions,M] = BalanceTrials((numDirections * numRepetitions*numModalities), 1, possible_directions,allModalities) % randomize the directions
    [directions,modalities] = BalanceTrials((numDirections * numRepetitions), 1, possibleDirections,possibleModalities);   % randomize the directions

    directions = repmat(directions,1,numEventsPerBlock);
    
    % check that no direction is repeated simultaneously 
    for i=1:size(directions,1)-1
        repeat(i)= directions(i,1)==directions(i+1,1) && strcmp(modalities{i},modalities(i+1));
    end
    repeat = sum(repeat);
end

% Get the number of the blocks in the run
numBlocks = size(directions,1);


speeds=ones(numBlocks,numEventsPerBlock)*speedEvent ;       % a matrix of speed values for each event 
fixationTargets = zeros(numBlocks,numEventsPerBlock) ;     % a matrix of presence of target fixation for each event

% Targets empty vector
targetsIdx = [];
fixationTargetsIdx = [];


for iBlock =1:numBlocks
   
    if numTargetPerBlock > 0                                 % If 1 target or more present

        targethalf1 = randi([2 (numEventsPerBlock/2)-1],1);  % get a random target from 1st half of the block
        targethalf2 = randi([(numEventsPerBlock/2)+1 (numEventsPerBlock-1)],1); % get a random target from 2st half of the block

        targetsIdx_tmp = [targethalf1 targethalf2];       % concatenate the targets in one vector

        if numTargetPerBlock == 1                            % If only one target is required
            t = targetsIdx_tmp;
            targetsIdx = t(randi([1,2],1));           % randomly pick one from the target vector
        else
            targetsIdx = targetsIdx_tmp;
        end
            

        speeds(iBlock,targetsIdx) = speedTarget;      % replace the speed with their target speed

    end
    
    % fixation targets
    if numFixationTargets > 0
                
        ConflictingTargets = 1 ;                            % ensure that fixation targets and normal targets dont come together
        while ConflictingTargets > 0
            %fixationTargets_tmp = datasample([2:numEventsPerBlock-1],numFixationTargets,'Replace',false) ; 
            fixationTargethalf1 = randi([2 (numEventsPerBlock/2)-1],1);  % get a random target from 1st half of the block
            fixationTargethalf2 = randi([(numEventsPerBlock/2)+1 (numEventsPerBlock-1)],1); % get a random target from 2st half of the block
            fixationTargets_tmp = [fixationTargethalf1 fixationTargethalf2];
            
            if numFixationTargets == 1                            % If only one target is required
                f = fixationTargets_tmp;
                fixationTargetsIdx = f(randi([1,2],1));           % randomly pick one from the target vector
            else
                fixationTargetsIdx = fixationTargets_tmp;
            end
            
            ConflictingTargets = sum(ismember(fixationTargetsIdx,targetsIdx))              % Check if they are conflicting

        end
        
        %fixationTargetsIdx(iBlock,:)= fixationTargets_tmp;
        
    end
    
    fixationTargets(iBlock,fixationTargetsIdx) = 1 ;
    
end


%% Display the direction and speed matrices
if displayFigs
    figure();
    subplot(2,2,1)
    imagesc(directions)
    title('Directions')
    colorbar()
    subplot(2,2,2)
    imagesc(speeds)
    title('Speed')
    colorbar()
    subplot(2,2,4)
    imagesc(fixationTargets)
    title('Fixation Targets')
    colorbar()
end
    
    
end


%% Trial Cfg 
% Setting a trial Cfg for testing purposes only
function Cfg = trial_Cfg()

Cfg.possibleModalities = {'visual','auditory','AV'};

Cfg.possibleDirections = [0 90 180 270];                   % possible motion angles  (-1 is for static)
Cfg.names = {'right','up','left','down'};

Cfg.numRepetitions         = 1 ;
Cfg.speedEvent             = 6 ;
Cfg.speedTarget            = 7 ;
Cfg.numEventsPerBlock      = 8 ;
Cfg.maxNumTargetPerBlock   = 2 ;
Cfg.eventDuration          = 2 ; 
Cfg.interstimulus_interval = 0.1 ;                   % time between events in secs
Cfg.interBlock_interval    = 4 ;
Cfg.response_time          = 1 ;
Cfg.numTargetPerBlock      = 2; 

Cfg.numFixationTargets = 2; 

%%
end

