function [estim, searchoptims, searchpoints] = pret_estimate(data,samplerate,trialwindow,model,wnum,options)
% pret_estimate
% [estim, searchoptims, searchpoints] = pret_estimate(data,samplerate,trialwindow,model)
% [estim, searchoptims, searchpoints] = pret_estimate(data,samplerate,trialwindow,model,options)
% options = pret_estimate()
% 
% Optimization algorithm for estimating the model parameters that result in
% the best fit to the data. First, the cost function is evaluated for a
% large number (default 2000) of points sampled from across 
% parameter space. Then, the subset (default 40) that evaluate to the lowest value
% of the cost function are used as starting points for fmincon. The output
% set of parameters that result in the lowest cost is taken as the best
% estimate.
% 
%   Inputs:
%   
%       data = a single pupil size time series as a row vector.
% 
%       samplerate = sampling rate of data in Hz.
% 
%       trialwindow = a 2 element vector containing the starting and ending
%       times (in ms) of the trial epoch. Will NOT be the window the model
%       is estimated on (that is in model.window).
% 
%       model = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, model.yintval, and model.slopeval do not need to be 
%       provided if they are being estimated but should be provided if they 
%       are not.
% 
%       wnum = number of workers used by matlab's parallel pool to complete
%       the process (parpool will not be initialized if set to 1).
% 
%       options = options structure for pret_estimate. Default options can be
%       returned by calling this function with no arguments, or see
%       pret_default_options.
% 
%   Outputs:
% 
%       estim = a structure containing the parameters estimated by fmincon
%       with the following fileds:
%           eventtimes = a copy of eventtimes from "model".
%           boxtimes = a copy of boxtimes from "model".
%           samplerate = a copy of samplerate from "model".
%           window a copy of window from "model".
%           ampvals = the estimated event amplitude values.
%           boxampvals = the estimated box regressor amplitude values.
%           latvals = the estimated event latency values.
%           tmaxval = the estimated tmax value.
%           yintval = the estimated y-intercept value.
%           slopeval = the estimated slope value.
%           numparams = number of parameters fit.
%           cost = the sum of square errors between the optimized
%           parameters and the actual data.
%           R2 = the R^2 goodness of fit value
%           BICrel = the relative BIC value of the model fit
%               *relative because we use the guassian simplfictation of the
%               BIC
%               *since it is relative, only use to compare models/fits on
%               data from the same task
% 
%       *Note - can be input into pret_plot_model, pret_calc, or pret_cost in the 
%       place of the "model" input*
% 
%       searchoptims = an optional output structure containing the
%       parameters estimated by fmincon for all optimization runs.
%       It has the same fields as optim, but has a length equal to
%       options.optimnum.
% 
%   Options
%
%       options.searchnum (2000) = the number of points sampled from parameter
%       space where the cost function is evaluated.
% 
%       options.optimnum (40) = the number of optimizations to be run, using the
%       optimnum number of parameter points with the lowest costs.
% 
%       options.parammode ('uniform') = the mode used to generate the
%       parameters for the search of parameter space. See
%       pret_generate_params for more information.
% 
%       pret_generate_params_options = options structure for pret_generate_params, 
%       which pret_estimate uses to generate the parameters for the search of
%       parameter space.
% 
%       pret_optim_options = options structure for pret_optim, 
%       which pret_estimate uses to perform each individual optimization.
% 
%       pret_cost_options = options structure for pret_cost, which pret_estimate 
%       uses to evaluate the cost function at each point sampled from
%       parameter space.
% 
%       pret_model_check = options for pret_model_check
%
%   Jacob Parker 2018

if nargin < 6
    opts = pret_default_options();
    options = opts.pret_estimate;
    clear opts
    if nargin < 1
        estim = options;
        return
    end
end

%OPTIONS
pret_generate_params_options = options.pret_generate_params;
pret_optim_options = options.pret_optim;
pret_cost_options = options.pret_optim.pret_cost;
searchnum = options.searchnum;
optimnum = options.optimnum;
parammode = options.parammode;
pret_model_check_options = options.pret_model_check;

sfact = samplerate/1000;
time = trialwindow(1):1/sfact:trialwindow(2);

%check inputs
%simple check of input model structure
pret_model_check(model,pret_model_check_options)

%data is a vector
if size(data,1) ~= 1
    error('The "data" argument must be a row vector')
end

%samplerate, trialwindow vs data
if length(time) ~= length(data)
    error('The number of time points according to samplerate and trialwindow does not equal the number of data points in data')
end

%sample rate vs model sample rate
if samplerate ~= model.samplerate
    error('The input sample rate and the sample rate in model do not match')
end

%model time window vs time points
if ~(any(model.window(1) == time)) || ~(any(model.window(2) == time ))
    error('Model time window does not fall on time points according to sample rate and trial window')
end

%generate starting parameters for coarse search in parameter space
searchpoints = pret_generate_params(searchnum,parammode,model,pret_generate_params_options);

%crop data to match model.window
datalb = find(model.window(1) == time);
dataub = find(model.window(2) == time);
data = data(datalb:dataub);

%evaluate cost function with parameter sets distributed across the parameter
%space to determine which starting points to use for constrained
%optimization, which is time consuming and computationally intensive 
fprintf('\nDetermining best %d out of %d starting points for optimization algorithm\n',optimnum,searchnum)
search = search_param_space(data,searchnum,optimnum,model,searchpoints,pret_cost_options);
fprintf('Best %d starting points found\n',optimnum)

%create a model structure for each optimization to be completed (enables
%use of parfor loop)
modelstate(optimnum) = model;
for op = 1:optimnum
    modelstate(op) = model;
    modelstate(op).ampvals = search.ampvals(op,:);
    modelstate(op).boxampvals = search.boxampvals(op,:);
    modelstate(op).latvals = search.latvals(op,:);
    modelstate(op).tmaxval = search.tmaxvals(op,:);
    modelstate(op).yintval = search.yintvals(op,:);
    modelstate(op).slopeval = search.slopevals(op,:);
end  

%perform constrained optimization on the best points from the coarse
%parameter space search
searchoptims = struct('eventtimes',model.eventtimes,'boxtimes',{model.boxtimes},'samplerate',model.samplerate,'window',model.window,'ampvals',[],'boxampvals',[],'latvals',[],'tmaxval',[],'yintval',[],'slopeval',[],'numparams',[],'cost',[],'R2',[],'BICrel',[]);
tempcosts = nan(optimnum,1);
if wnum == 1
    fprintf('\nBeginning optimization of best starting points\nOptims completed: ')
    for op = 1:optimnum
        searchoptims(op) = pret_optim(data,modelstate(op).samplerate,modelstate(op).window,modelstate(op),pret_optim_options);
        tempcosts(op) = searchoptims(op).cost;
        fprintf('%d ',op)
    end
else
    p = gcp('nocreate');
    if isempty(p)
        parpool(wnum);
    end
    fprintf('\nBeginning optimization of best starting points\nOptims completed: ')
    parfor op = 1:optimnum
        searchoptims(op) = pret_optim(data,modelstate(op).samplerate,modelstate(op).window,modelstate(op),pret_optim_options);
        tempcosts(op) = searchoptims(op).cost;
        fprintf('%d ',op)
    end
end

fprintf('\nOptimizations completed!\n\n')
[~,minind] = min(tempcosts);
estim = searchoptims(minind);

    function search = search_param_space(data,searchnum,optimnum,modelstate,params,pret_cost_options)
        
        costs = nan(searchnum,1);
        for ss = 1:searchnum
            modelstate.ampvals = params.ampvals(ss,:);
            modelstate.latvals = params.latvals(ss,:);
            modelstate.tmaxval = params.tmaxvals(ss);
            modelstate.yintval = params.yintvals(ss);
            modelstate.slopeval = params.slopevals(ss);
            modelstate.boxampvals = params.boxampvals(ss,:);
            costs(ss) = pret_cost(data,modelstate.samplerate,modelstate.window,modelstate,pret_cost_options);
        end
        
        [~,sortind] = sort(costs);
        [~,rank] = sort(sortind);
        optimindex = find(rank <= optimnum);
        
        search.ampvals = params.ampvals(optimindex,:);
        search.latvals = params.latvals(optimindex,:);
        search.tmaxvals = params.tmaxvals(optimindex,:);
        search.yintvals = params.yintvals(optimindex,:);
        search.slopevals = params.slopevals(optimindex,:);
        search.boxampvals = params.boxampvals(optimindex,:);
        search.optimindex = optimindex;
        search.costs = costs;
        
    end

end
