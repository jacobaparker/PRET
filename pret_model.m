function model = pret_model()
% pret_model
% model = pret_model()
% 
% Creates a structure with all of the fields that must be filled in by the
% user to create a specific model. This structure provides information to
% functions about the form of the model.
% 
% Jacob Parker and Rachel Denison, 2019

%% preallocate model
model = struct('window',[]);

%% model time window and sample rate
% a two element vector delineating the end and start times (in ms) for the
% model (can be different than the trialwindow given for actual data)
%   > for example, if your trials are epoched -500 to 3500 ms, you might
%     only be interested in modeling 0 to 3500 ms
model.window = [];

% the sample rate (in Hz) you would like the model to work with (the
% samplerate in a sj structure will be used instead if used in a function
% that uses them)
model.samplerate = [];

%% set parameters on/off for model
model.ampflag = true;       %event amplitude to be estimated as a parameter: true/false
model.boxampflag = true;    %box amplitude to be estimated as a parameter: true/false
model.latflag = true;       %latency to be estimated as a parameter (not for boxes): true/false
model.tmaxflag = true;      %tmax to be estimated as a parameter: true/false
model.yintflag = true;      %y-intercept to be estimated as a parameter: true/false
model.slopeflag = true;

%% define instantaneous events/box regressors
% vectors containing the time of occurrence (in ms) for each
% instantaneous event and cell array of corresponding labels (optional)
model.eventtimes = [];
model.eventlabels = {};

% cell array of two element vectors, each containing the start and end
% times (in ms) for each box function regressor and cell array of
% corresponding labels (optional)
% **** Should the latency of this be allowed to be estimated? ****
model.boxtimes = {};
model.boxlabels = {};

%% define parameter boundaries for constrained optimization
% 2 by N matrices which contain the lower and upper bounds of each events's
% and each boxes's amplitude value for the constrained optimization. N is the 
% number of events or boxes. The lower bounds are in the first row and the 
% upper bounds are in the second row. 
% (not important if event or box amplitude not to be estimated)
model.ampbounds = [];
model.boxampbounds = [];

% a 2 by N matrix which contains the lower and upper bounds of each events's
% latency for the constrained optimization. N is the number of events. 
% The lower bounds are in the first row and the upper bounds are in the 
% second row. (not important if latency not to be estimated)
% REMINDER: latency refers to the time shift (in ms) relative to a
% regressor's actual event time (entered in model.eventtimes), NOT the actual
% time values of the event (a value of 0 means pupil response starts at the 
% same time as the actual event)
model.latbounds = [];

% two element vectors containing the lower and upper bounds (in that
% order) of the tmax and y-intercept values for the constrained optimization 
% (not important if tmax and/or y-intercept not to be estimated)
model.tmaxbounds = [];
model.yintbounds = [];
model.slopebounds = [];


%% define default parameter values
% vectors of default amplitude values, one for each event and box regressor
% (must be provided if not being estimated as a parameter in the model)
model.ampvals = [];
model.boxampvals = [];

% vector of default latency values, one for each event
% (must be provided if not being estimated as a parameter)
model.latvals = [];

% default tmax (in ms) and y-intercept values (only one value each) (must
% be provided if not being estimated)
model.tmaxval = [];
model.yintval = [];
model.slopeval = [];

