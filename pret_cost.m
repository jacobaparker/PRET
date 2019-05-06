function cost = pret_cost(data,samplerate,trialwindow,model,options)
% pret_cost
% cost = pret_cost(data,samplerate,trialwindow,model)
% cost = pret_cost(data,samplerate,trialwindow,model,options)
% options = pret_cost()
% 
% Calculates the sum of the square errors between some input pupil size
% time series "data" and a time series created from the specifications and
% parameters in "model".
% 
%   Inputs:
%   
%       data = a single pupil size time series as a row vector.
% 
%       samplerate = sampling rate of data in Hz.
% 
%       trialwindow = a 2 element vector containing the starting and ending
%       times (in ms) of the trial epoch.
% 
%       model = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, and model.yintval must be provided.
%           *Note - an optim structure from pret_estimate, pret_bootstrap, or
%           pret_optim can be input in the place of model*
% 
%       options = options structure for pret_cost. Default options can be
%       returned by calling this function with no arguments.
% 
%   Outputs:
% 
%       cost = sum of the square errors between "data" and time series
%       created using "model"
% 
%   Options
%
%       pret_calc_options = options structure for pret_calc, which pret_cost uses
%       to produce the time series from "model".
%
%   Jacob Parker and Rachel Denison, 2019

if nargin < 5
    opts = pret_default_options();
    options = opts.pret_cost;
    clear opts
    if nargin < 1
        cost = options;
        return
    end
end

%OPTIONS
pret_calc_options = options.pret_calc;

sfact = samplerate/1000;
time = trialwindow(1):1/sfact:trialwindow(2);

%check inputs
pret_model_check(model)

%samplerate, trialwindow vs data
if length(time) ~= length(data)
    error('The number of time points does not equal the number of data points')
end

%sample rate vs model sample rate
if samplerate ~= model.samplerate
    error('The input sample rate and the sample rate in model do not match')
end

%model time window vs time points
if ~(any(model.window(1) == time)) || ~(any(model.window(2) == time ))
    error('Model time window does not fall on time points according to sample rate and trial window')
end

%how many time series to fit simultaneously?
nts = size(data,1);

%crop data to match model.window
datalb = find(model.window(1) == time);
dataub = find(model.window(2) == time);
data = data(:,datalb:dataub);

Ycalc = pret_calc(model,pret_calc_options);

if nts>1
    % concatenate time series
    temp = data';
    data = temp(:)';
    
    % concatenate model prediction
    Ycalc = repmat(Ycalc,1,nts);
end

cost = sum((data-Ycalc).^2);

