function [boots, bootestims] = pret_bootstrap(data,samplerate,trialwindow,model,nboots,wnum,options)
% pret_bootstrap
% boots = pret_bootstrap(data,samplerate,trialwindow,model,nboots,wnum)
% boots = pret_bootstrap(data,samplerate,trialwindow,model,nboots,wnum,options)
% [boots, bootestims] = pret_bootstrap(data,samplerate,trialwindow,model,nboots,wnum,options)
% options = pret_bootstrap()
% 
% Bootstrapping procedure for estimating model parameters. Calculates a set
% of bootstrapped means from the data provided, then performs the
% optimization algorithm on each bootstrapped mean.
% 
%   Inputs:
%   
%       data = a 2D matrix containing all of the trials for one mean, in
%       the form of trial by time.
% 
%       samplerate = sampling rate of data in Hz.
% 
%       trialwindow = a 2 element vector containing the starting and ending
%       times (in ms) of the trial epoch.
% 
%       model = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, model.yintval, and model.slopeval do NOT need to be 
%       provided (unless any of those parameters are not being estimated).
% 
%       nboots = number of bootstrap iterations to perform.
% 
%       wnum = number of workers used by matlab's parallel pool to complete
%       the process (parpool will not be initialized if set to 1).
% 
%       options = options structure for pret_bootstrap. Default options can be
%       returned by calling this function with no arguments, or see
%       pret_default_options.
% 
%   Outputs:
% 
%       boots = a structure containing the parameters estimated for each
%       bootstrap iteration. It contains the following fields:
%           eventtimes = a copy of eventtimes from "model".
%           boxtimes = a copy of boxtimes from "model".
%           samplerate = a copy of samplerate from "model".
%           window = a copy of window from "model".
% 
%           ampvals = the estimated event amplitude values for each
%           bootstrap iteration, where the fist dimension is bootstrap
%           iteration and the second dimension is event.
%           boxampvals = the estimated box regressor amplitude values.
%           latvals = the estimated event latency values.
%           tmaxvals = the estimated tmax values.
%           yintvals = the estimated y-intercept values.
%           slopevals = the estimated slope values
% 
%           cost = the sum of square errors between the optimized
%           parameters and the actual data.
%           R2 = the R^2 goodness of fit value.
%           BICrel = the relative BIC value of the model fit
%               *relative because we use the guassian simplfictation of the
%               BIC
%               *since it is relative, only use to compare models/fits on
%               data from the same task
% 
%           ampmedians, boxampmedians, latmedians, tmaxmedian, yintmedian, slopemedian =
%           the medians of ampvals, boxampvals, latvals, tmaxvals, yintvals, 
%           and slopevals respectively.
% 
%           amp95CIs, boxamp95CIs, lat95CIs, tmax95CI, yint95CI, slope95CI = 
%           the 95 confidence intervals of ampvals, boxampvals, latvals, 
%           tmaxvals, yintvals, and slopevals respectively.
% 
%       bootestims = an optional output option. A structure with a length
%       of nboots, where each element is an estim structure output by
%       running pret_estimate for single bootstrap iteration.
%           *Note - each estim structure can be input into pret_plot_model, pret_calc, 
%           or pret_cost in the place of the "model" input*
% 
%   Options
% 
%       bootplotflag (true/false) = plot summary figures with the
%       distribution of each parameter's bootstrap estimations.
% 
%       pret_estimate_options = options structure for pret_estimate, 
%       which pret_bootstrap uses to perform each bootstrap iteration.
% 
%       pret_model_check = options for pret_model_check
%
%   Jacob Parker 2018

if nargin < 7
    opts = pret_default_options();
    options = opts.pret_bootstrap;
    clear opts
    if nargin < 1
        boots = options;
        return
    end
end

%OPTIONS
bootplotflag = options.bootplotflag;
pret_estimate_options = options.pret_estimate;
pret_model_check_options = options.pret_model_check;

sfact = samplerate/1000;
time = trialwindow(1):1/sfact:trialwindow(2);

%check inputs
%simple check of input model structure
pret_model_check(model,pret_model_check_options)

%samplerate, trialwindow vs data
if length(time) ~= size(data,2)
    error('The number of time points according to samplerate and trialwindow does not equal the number of data points (2nd dimension of data) in a trial')
end

%sample rate vs model sample rate
if samplerate ~= model.samplerate
    error('The input sample rate and the sample rate in model do not match')
end

%model time window vs time points
if ~(any(model.window(1) == time)) || ~(any(model.window(2) == time ))
    error('Model time window does not fall on time points according to sample rate and trial window')
end

%crop data to match model.window
datalb = find(model.window(1) == time);
dataub = find(model.window(2) == time);
data = data(:,datalb:dataub);

%create bootstrap means of trials in data
rng(0)
means = bootstrp(nboots,@nanmean,data);

bootestims = struct('eventtimes',model.eventtimes,'boxtimes',model.boxtimes,'samplerate',model.samplerate,'window',model.window,'ampvals',[],'boxampvals',[],'latvals',[],'tmaxval',[],'yintval',[],'slopeval',[],'numparams',[],'cost',[],'R2',[],'BICrel',[]);
modelsamplerate = model.samplerate;
modelwindow = model.window;

%estimate model parameters for each bootstrap mean
fprintf('\nBeginning bootstrapping, %d iterations to be completed\n',nboots)
if wnum == 1
    for nb = 1:nboots
        fprintf('\nStart iteration %d\n',nb)
        bootestims(nb) = pret_estimate(means(nb,:),modelsamplerate,modelwindow,model,1,pret_estimate_options);
        fprintf('\nEnd iteration %d\n',nb)
    end
else
    p = gcp('nocreate');
    if isempty(p)
        parpool(wnum);
    end
    parfor nb = 1:nboots
        fprintf('\nStart iteration %d\n',nb)
        bootestims(nb) = pret_estimate(means(nb,:),modelsamplerate,modelwindow,model,1,pret_estimate_options);
        fprintf('\nEnd iteration %d\n',nb)
    end
end
fprintf('Boostrapping completed!\n')

boots = struct('eventtimes',model.eventtimes,'boxtimes',{model.boxtimes},'samplerate',model.samplerate,'window',model.window,'ampvals',nan(nboots,length(model.eventtimes)),'boxampvals',nan(nboots,length(model.boxtimes)),'latvals',nan(nboots,length(model.eventtimes)),'tmaxvals',nan(nboots,1),'yintvals',nan(nboots,1),'slopevals',nan(nboots,1),'costs',nan(nboots,1),'R2',nan(nboots,1));

for nb = 1:nboots
    boots.ampvals(nb,:) = bootestims(nb).ampvals;
    boots.boxampvals(nb,:) = bootestims(nb).boxampvals;
    boots.latvals(nb,:) = bootestims(nb).latvals;
    boots.tmaxvals(nb,:) = bootestims(nb).tmaxval;
    boots.yintvals(nb,:) = bootestims(nb).yintval;
    boots.slopevals(nb,:) = bootestims(nb).slopeval;
    boots.costs(nb) = bootestims(nb).cost;
    boots.R2(nb) = bootestims(nb).R2;
end

boots.ampmedians = nanmedian(boots.ampvals,1);
boots.boxampmedians = nanmedian(boots.boxampvals,1);
boots.latmedians = nanmedian(boots.latvals,1);
boots.tmaxmedian = nanmedian(boots.tmaxvals,1);
boots.yintmedian = nanmedian(boots.yintvals,1);
boots.slopemedian = nanmedian(boots.slopevals,1);

boots.amp95CIs = [prctile(boots.ampvals,2.5,1) ; prctile(boots.ampvals,97.5,1)];
boots.boxamp95CIs = [prctile(boots.boxampvals,2.5,1) ; prctile(boots.boxampvals,97.5,1)];
boots.lat95CIs = [prctile(boots.latvals,2.5,1) ; prctile(boots.latvals,97.5,1)];
boots.tmax95CI = [prctile(boots.tmaxvals,2.5) ; prctile(boots.tmaxvals,97.5)];
boots.yint95CI = [prctile(boots.yintvals,2.5) ; prctile(boots.yintvals,97.5)];
boots.slope95CI = [prctile(boots.slopevals,2.5) ; prctile(boots.slopevals,97.5)];

if bootplotflag
    pret_plot_boots(boots,model);
end
