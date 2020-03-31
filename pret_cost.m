function [cost, Ycalc, data] = pret_cost(data,samplerate,trialwindow,model,options)
% pret_cost
% [cost, Ycalc, data] = pret_cost(data,samplerate,trialwindow,model)
% [cost, Ycalc, data] = pret_cost(data,samplerate,trialwindow,model,options)
% options = pret_cost()
% 
% Calculates the sum of the square errors between some input pupil size
% time series "data" and a time series created from the specifications and
% parameters in "model". If a MxN matrix with M time series is input into
% "data", the cost will be computed between each time series and the single 
% time series produced from "model" and summed.
% 
%   Inputs:
%   
%       data = a single pupil size time series as a row vector OR a MxN
%       matrix with M time series.
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

%are distinct event timings specified for each trial?
ntr = size(model.eventtimes,1);

%crop data to match model.window
datalb = find(model.window(1) == time);
dataub = find(model.window(2) == time);
data = data(:,datalb:dataub);

for itr = 1:ntr
    mtr = model;
    mtr.eventtimes = model.eventtimes(itr,:);
    for ibox = 1:numel(model.boxtimes)
        mtr.boxtimes{ibox} = model.boxtimes{ibox}(itr,:);
    end
    Ycalc(itr,:) = pret_calc(mtr,pret_calc_options);
end

if nts>1
    % concatenate time series
    temp = data';
    data = temp(:)';
    
    % concatenate model prediction
    if ntr>1
        temp = Ycalc';
        Ycalc = temp(:)';
    else
        Ycalc = repmat(Ycalc,1,nts);
    end
end

cost = nansum((data-Ycalc).^2);

