function logfileToOnsets(logFile_Name)
% Function that converts the log file from the localizer into an onset file
% to be used in SPM directly. 
% N.B: Onsets and durations are converted to TRs.

% If logFile name is not given as input , ask for it.
if nargin<1
    logFile_Name=input('Enter the logfile Name: ','s') ;
end

% The length of 1 TR in seconds
TR = 2 ;   

% load the logFile
load (logFile_Name)


% Convert time from seconds to TRs
tmp_onsets = onsets/TR ;
tmp_durations = durations/TR ;

clear onsets; clear durations;

% Get the conditions names 
uniqueNames = unique(names);

% Create onsets & durations empty cells.
onsets    = cell(1,length(uniqueNames)) ;
durations = cell(1,length(uniqueNames)) ;


%% Get onsets, durations, and names in SPM compatible format
% each should be a cell with dimensions 1Xn.
for iUniqueName = 1:length(uniqueNames)
    onsets{iUniqueName}    = tmp_onsets(strcmp(names,uniqueNames{iUniqueName}))'      ;
    durations{iUniqueName} = tmp_durations(strcmp(names,uniqueNames{iUniqueName}))'   ;    
end
names = uniqueNames' ;
    
%% Save the onsets file for SPM
save(['Onsets_',logFile_Name(9:end)],'names','onsets','durations')

end
