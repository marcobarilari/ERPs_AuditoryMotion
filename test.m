function test(varargin)

% list = varargin;

celldisp(varargin)

d=sum(varargin{:});

disp(d)

end

nm = timeLogger(:).names

struct2cell(timeLogger(:).names)

t = table(struct2array(timeLogger.names),struct2cell(timeLogger.isTarget));


,timeLogger.isTarget, ...
    timeLogger.soundcode, ...
    timeLogger.ISI, ...
    timeLogger.endTime, ...
    timeLogger.response, ...
    timeLogger.responseTime););


