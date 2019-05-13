function [data, outparams] = pret_fake_data(numtseries,parammode,samplerate,trialwindow,model,options)
% pret_fake_data
% data = pret_fake_data(numtseries,parammode,samplerate,trialwindow,model)
% data = pret_fake_data(numtseries,parammode,samplerate,trialwindow,model,options)
% 
% Generates fake pupil size time series using randomly generated parameters for
% a given model.
% 
%   Inputs:
%   
%       numtseries = number of time series to generate
% 
%       parammode ('uniform', 'normal', or 'space_optimal') = mode used to
%       generate parameters.
%           'uniform' - parameters are attempted to be sampled evenly
%           from the range of their respective bounds. When the number of 
%           points sampled is relatively low, binning can help span the 
%           parameter space. For each parameter, the range is split up 
%           into options.nbins number of bins and a floor(num/nbins) number 
%           of points is randomly and uniformly sampled from each bin. The 
%           remaining points are then sampled from the entire range. 
%           'normal' - parameters are drawn from a normal distrubtion
%           centered around the values provided in the input model
%           structure. The standard deviation is set by options.sigma.
% 
%       samplerate = sampling rate of data in Hz. Can be different than the
%       value in the model.samplerate if desired.
% 
%       trialwindow = a 2 element vector containing the starting and ending
%       times (in ms) of the trial epoch. Can be different than
%       model.window if desired.
% 
%       model = model structure created by pret_model and filled in by user.
%           *IMPORTANT - parameter values in model.ampvals,
%           model.boxampvals, model.latvals, model.tmaxval, model.yintval, 
%           and model.slopeval must be provided if 'normal' parammode is used!
% 
%       options = options structure for pret_fake_data. Default options 
%       can be returned by calling this function with no arguments, or see
%       pret_default_options.
% 
%   Outputs:
% 
%       data = a 2D matrix where each row is a generated pupil size time
%       series.
% 
%      outparams = an output structure containing all sets of parameters
%      generated to create fake data. Contains the following fields:
%           ampvals = 2D matrix of generated event amplitude parameters.
%           Each row is one set of parameters.
%           boxampvals = 2D matrix of generated box amplitude parameters.
%           latvals = 2D matrix of generated event latency parameters.
%           tmaxvals = column vector of generated tmax parameters.
%           yintvals = column vector of generated y-intercept parameters.
%           slopevals = column vector of generated slope parameters.
%           
% 
%   Options
% 
%       pret_generate_params = options structure for pret_generate_params,
%       which pret_fake_data uses to generate parameter values that the
%       artificial time series are constructed from. Options for the
%       various "parammode" options are in here.
% 
%       pret_model_check = options for pret_model_check
%
% 
%     Copyright (C) 2019  Jacob Parker and Rachel Denison
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <https://www.gnu.org/licenses/>.
% 

if nargin < 6
    opts = pret_default_options();
    options = opts.pret_fake_data;
    clear opts
    if nargin < 1
        data = options;
        return
    end
end

%OPTIONS
pret_generate_params_options = options.pret_generate_params;
pret_model_check_options = options.pret_model_check;

%check inputs
pret_model_check(model,pret_model_check_options)

sfact = samplerate/1000;
time = trialwindow(1):1/sfact:trialwindow(2);

%model time window vs time points
if ~(any(trialwindow(1) == time)) || ~(any(trialwindow(2) == time ))
error('Given trial window does not fall on time points according to sample rate and trial window')
end

data = nan(numtseries,length(time));
modelstate = model;
modelstate.window = trialwindow;
modelstate.samplerate = samplerate;


%generate parameters to create time series with
params = pret_generate_params(numtseries,parammode,model,pret_generate_params_options);

%generate time series from parameters
for ts = 1:numtseries
    if ~isempty(model.eventtimes)
        modelstate.ampvals = params.ampvals(ts,:);
        modelstate.latvals = params.latvals(ts,:);
        modelstate.tmaxval = params.tmaxvals(ts);
        modelstate.yintval = params.yintvals(ts);
        modelstate.slope = params.slopevals(ts);
    end
    if ~isempty(model.boxtimes)
        modelstate.boxampvals = params.boxampvals(ts,:);
    end
    data(ts,:) = pret_calc(modelstate);
end

outparams = struct('eventimes',model.eventtimes,'boxtimes',model.boxtimes,'ampvals',params.ampvals,'boxampvals',params.boxampvals,'latvals',params.latvals,'tmaxvals',params.tmaxvals,'yintvals',params.yintvals,'slopevals',params.slopevals);

