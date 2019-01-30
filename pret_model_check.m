function pret_model_check(model,options)
% pret_model_check
% pret_model_check(model)
% pret_model_check(model,options)
% 
% Checks if the specifications in "model" are valid. If a model is not
% valid, will throw an error. Otherwise, if a model is valid, no error will
% be thrown.
% 
% Inputs:
% 
%   model = model structure to be checked
% 
% Options:
% 
%   checkparams: (true/false) = check if parameter values filled out, even
%   for models where those parameters are being fit (default = false)
% 
% Jacob Parker 2018

if nargin < 2
    opts = pret_default_options();
    options = opts.pret_model_check;
    clear opts
end

%OPTIONS
checkparams = options.checkparams;

%% window
if length(model.window) ~= 2
    error('model.window must be a two element vector')
end

%% samplerate
if length(model.samplerate) ~= 1
    error('model.samplerate must be provided as a single value')
end

sfact = model.samplerate/1000;
time = model.window(1):1/sfact:model.window(2);
if ~(any(model.window(1) == time)) || ~(any(model.window(2) == time))
    error('"model.window" not compatible with "model.samplerate"')
end

%% event times
if isempty(model.eventtimes) && (model.ampflag || model.latflag)
    error('If event amplitude and/or event latency is to be estimated,\nevent times must be provided in model.eventtimes')
end

%% box times
if isempty(model.boxtimes) && model.boxampflag
    error('If box amplitude is to be estimated, box times must be provided')
end

%% event amplitude
if model.ampflag
    if ~isempty(model.eventtimes)
        if length(model.eventtimes) ~= size(model.ampbounds,2)
            error('Number of event amplitude bounds in model not equal to number of events')
        end
        if checkparams
            if length(model.eventtimes) ~= length(model.ampvals)
                error('Number of default event amplitudes not equal to number of events')
            end
            for ii = 1:length(model.eventtimes)
                if (model.ampvals(ii) < model.ampbounds(1,ii)) || (model.ampvals(ii) > model.ampbounds(2,ii))
                    error('At least one given amplitude value in model.ampvals is outside of its\nbounds according to the info in model.ampbounds')
                end
            end
        end
    end
else
    if length(model.eventtimes) ~= length(model.ampvals)
        error('Number of defualt event amplitudes not equal to number of events')
    end
end

%% box amplitude
if ~isempty(model.boxtimes)
    for ii = 1:length(model.boxtimes)
        if length(model.boxtimes{ii}) ~= 2
            error('All cells in boxtimes must be a 2 element vector')
        end
        if ~(any(model.boxtimes{ii}(1) == time)) || ~(any(model.boxtimes{ii}(2) == time))
            if (rem(model.boxtimes{ii}(2)-time(end),1/sfact) == 0) && (rem(model.boxtimes{ii}(1)-time(1),1/sfact) == 0)
                % box times can fall outside model.window, but must be on
                % the time vector if it were to be extended
            else
                error('Box %d start and end time points do not fall on time vector defined by\nmodel.window and model.samplerate',ii)
            end
        end
    end
end
if model.boxampflag
    if ~isempty(model.boxtimes)
        if length(model.boxtimes) ~= size(model.boxampbounds,2)
            error('Number of box amplitude bounds in model not equal to number of boxes')
        end
        if checkparams
            if length(model.boxtimes) ~= length(model.boxampvals)
                error('\nNumber of default box amplitude values does not match number of boxes\n')
            end
            for ii = 1:length(model.boxtimes)
                if (model.boxampvals(ii) < model.boxampbounds(1,ii)) || (model.boxampvals(ii) > model.boxampbounds(2,ii))
                    error('At least one given box amplitude value in model.boxampvals is outside of its\nbounds according to the info in model.boxampbounds')
                end
            end
        end
    end
else
    if length(model.boxtimes) ~= length(model.boxampvals)
        error('Number of default box amplitudes not equal to number of boxes')
    end
end

%% event latency
if model.latflag
    if ~isempty(model.eventtimes)
        if length(model.eventtimes) ~= size(model.latbounds,2)
            error('Number of event latency bounds in model not equal to number of events')
        end
        if checkparams
            if length(model.eventtimes) ~= length(model.latvals)
                error('\nNumber of default event latency values does not match number of events\n')
            end
            for ii = 1:length(model.eventtimes)
                if (model.latvals(ii) < model.latbounds(1,ii)) || (model.latvals(ii) > model.latbounds(2,ii))
                    error('At least one given latency value in model.latvals is outside of its\nbounds according to the info in model.latbounds')
                end
            end
        end
    end
else
    if length(model.eventtimes) ~= length(model.latvals)
        error('Number of default event latency not equal to number of events')
    end
end

%% tmax
if model.tmaxflag
    if length(model.tmaxbounds) ~= 2
        error('model.tmaxbounds should be a 2 element vector')
    end
    if checkparams
        if length(model.tmaxval) ~= 1
            error('\nNumber of default tmax values not equal to 1\n')
        end
        if (model.tmaxval < model.tmaxbounds(1)) || (model.tmaxval > model.tmaxbounds(2))
            error('Given tmax value in model.tmaxval is outside of its\nbounds according to the info in model.tmaxbounds')
        end
    end
else
    if length(model.tmaxval) ~= 1
        error('Number of default tmax values not equal to 1')
    end
end

%% y-intercept
if model.yintflag
    if length(model.yintbounds) ~= 2
        error('model.yintbounds should be a 2 element vector')
    end
    if checkparams
        if length(model.yintval) ~= 1
            error('Number of default y-intercept values not equal to 1')
        end
        if (model.yintval < model.yintbounds(1)) || (model.yintval > model.yintbounds(2))
            error('Given yint value in model.yintval is outside of its\nbounds according to the info in model.yintbounds')
        end
    end
else
    if length(model.yintval) ~= 1
        error('Number of default y-intercept values not equal to 1')
    end
end

%% slope
if model.slopeflag
    if length(model.slopebounds) ~= 2
        error('model.slopebounds should be a 2 element vector')
    end
    if checkparams
        if length(model.slopeval) ~= 1
            error('Number of default slope values not equal to 1')
        end
        if (model.slopeval < model.slopebounds(1)) || (model.slopeval > model.slopebounds(2))
            error('Given slope value in model.slopeval is outside of its\nbounds according to the info in model.slopebounds')
        end
    end
else
    if length(model.slopeval) ~= 1
        error('Number of default slope values not equal to 1')
    end
end
