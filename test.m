% function test(varargin)
% 
% % list = varargin;
% 
% celldisp(varargin)
% 
% d=sum(varargin{:});
% 
% disp(d)
% 
% end


[t, table_header] = make_events(SubjName, task_id, Run, onsets, durations, conditions', ...
    names, ...
    isTargets', ...
    Event_order', ...
    ISI', ...
    eventEnds', ...
    responses', ...
    responsesTime');


% t = table(onsets, durations, conditions');
