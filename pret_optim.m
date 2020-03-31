function optim = pret_optim(data,samplerate,trialwindow,model,options)
% pret_optim
% optim = pret_optim(data,samplerate,trialwindow,model)
% optim = pret_optim(data,samplerate,trialwindow,model,options)
% options = pret_optim()
% 
% Constrained optimization to find the model parameters for a given model
% that best matches the time series input as "data". Performs a single
% optimization using the parameter values in "model" as the starting point.
% 
% *NOTE: It is recommended to use pret_estimate, which performs an initial
% coarse search and then selects the best starting points for optimization
% with pret_optim.*
% 
%   Inputs:
%   
%       data = a single pupil size time series as a row vector OR an MxN
%       matrix with M time series. If a matrix, will compute single set of
%       parameters minimizing the cost for all time series.
% 
%       samplerate = sampling rate of data in Hz.
% 
%       trialwindow = a 2 element vector containing the starting and ending
%       times (in ms) of the trial epoch.
% 
%       model = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, model.yintval, and model.slopeval MUST be provided. 
%       These values are the starting point for the optimization.
% 
%       options = options structure for pret_optim. Default options can be
%       returned by calling this function with no arguments.
% 
%   Outputs:
% 
%       optim = a structure containing the parameters estimated by fmincon
%       with the following fileds:
%           eventtimes = a copy of eventtimes from "model".
%           boxtimes = a copy of boxtimes from "model".
%           samplerate = a copy of samplerate from "model".
%           window = a copy of window from "model".
%           ampvals = the event amplitude values fit by fmincon.
%           boxampvals = the box regressor amplitude values fit.
%           latvals = the event latency values fit.
%           tmaxval = the tmax value fit.
%           yintval = the y-intercept value fit.
%           slopeval = the slope value fit.
%           numparams = number of parameters fit.
%           cost = the sum of square errors between the optimized
%           parameters and the actual data.
%           R2 = the R^2 goodness of fit value.
%           BICrel = the relative BIC value of the model fit
%               *relative because we use the guassian simplfictation of the
%               BIC
%               *since it is relative, only use to compare models/fits on
%               data from the same task
% 
%       *Note - "optim" can be input into pret_plot_model and pret_calc in 
%       place of the "model" input*
% 
%   Options
%
%       optimplotflag (true/false) = plot optimization in realtime? Set
%       to false if you want speed.
% 
%       pret_cost = options structure for pret_cost, which pret_optim uses
%       as the cost function for fmincon.
% 
%       ampfact (1/10) = scaling factor for the event amplitude parameters. 
%       Parameters should be scaled so that their ranges are of similar magnitude.
%       This improves the performance of fmincon.
% 
%       boxampfact (1/10) = scaling factor for the box amplitude parameters.
% 
%       latfact (1/1000) = scaling factor for the latency parameters.
% 
%       tmaxfact (1/1000) = scaling factor for the tmax parameter.
% 
%       yintfact (1/10) = scaling factor for the yint parameter.
% 
%       slopefact (100) = scaling factor for the slope parameter.
% 
%       fmincon.
%           A, B, Aeq, Beq, NONLCON, options = input arguments/options
%           for fmincon. See documentation for fmincon for more details.
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

if nargin < 5
    opts = pret_default_options();
    options = opts.pret_optim;
    clear opts
    if nargin < 1
        optim = options;
        return
    end
end

%OPTIONS
optimplotflag = options.optimplotflag;
pret_cost_options = options.pret_cost;
pret_model_check_options = options.pret_model_check;

%Factors to scale parameters by so that they are of a similar magnitude.
%Improves performance of the constrained optimization algorithm (fmincon)
ampfact = options.ampfact;
boxampfact = options.boxampfact;
latfact = options.latfact;
tmaxfact = options.tmaxfact;
yintfact = options.yintfact;
slopefact = options.slopefact;

%input values/options for fmincon
A = options.fmincon.A;
B = options.fmincon.B;
Aeq = options.fmincon.Aeq;
Beq = options.fmincon.Beq;
NONLCON = options.fmincon.NONLCON;
fmincon_options = options.fmincon.options;

sfact = samplerate/1000;
time = trialwindow(1):1/sfact:trialwindow(2);

%check inputs
pret_model_check(model,pret_model_check_options)

%data is a vector
% if size(data,1) ~= 1
%     error('The "data" argument must be a row vector')
% end

%samplerate, trialwindow vs data
if length(time) ~= size(data,2)
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

%crop data to match model.window
datalb = find(model.window(1) == time);
dataub = find(model.window(2) == time);
data = data(:,datalb:dataub);

%recalculate time point vector
time = model.window(1):1/sfact:model.window(2);

%construct inputs into fmincon (X, bounds, etc)
X=[]; lb=[]; ub=[]; numparams = 0;

if model.ampflag
    X = model.ampvals .* ampfact;
    lb = model.ampbounds(1,:) .* ampfact;
    ub = model.ampbounds(2,:) .* ampfact;
    numparams = numparams + length(model.ampvals);
end

if model.boxampflag
    X = [X model.boxampvals.*boxampfact];
    lb = [lb model.boxampbounds(1,:).*boxampfact];
    ub = [ub model.boxampbounds(2,:).*boxampfact];
    numparams = numparams + length(model.boxampvals);
end

if model.latflag
    X = [X model.latvals.*latfact];
    lb = [lb model.latbounds(1,:).*latfact];
    ub = [ub model.latbounds(2,:).*latfact];
    numparams = numparams + length(model.latvals);
end
    
if model.tmaxflag
    X = [X model.tmaxval.*tmaxfact];
    lb = [lb model.tmaxbounds(1).*tmaxfact];
    ub = [ub model.tmaxbounds(2).*tmaxfact];
    numparams = numparams + length(model.tmaxval);
end

if model.yintflag
    X = [X model.yintval.*yintfact];
    lb = [lb model.yintbounds(1).*yintfact];
    ub = [ub model.yintbounds(2).*yintfact];
    numparams = numparams + length(model.yintval);
end

if model.slopeflag
    X = [X model.slopeval.*slopefact];
    lb = [lb model.slopebounds(1).*slopefact];
    ub = [ub model.slopebounds(2).*slopefact];
    numparams = numparams + length(model.slopeval);
end

% define cost function
f = @(X)optim_cost(X,data,model);

if optimplotflag
    fmincon_options.OutputFcn = @fmincon_outfun;
end

% define variables used during optimization
SSt = nansum((data(:)-nanmean(data(:))).^2); % for R2 calculation

% do the optimization
[X, cost] = fmincon(f,X,A,B,Aeq,Beq,lb,ub,NONLCON,fmincon_options);

% organize optimization results
model = unloadX(X,model);
optim = struct('eventtimes',model.eventtimes,'boxtimes',{model.boxtimes},...
    'samplerate',model.samplerate,'window',model.window,...
    'ampvals',model.ampvals,'boxampvals',model.boxampvals,...
    'latvals',model.latvals,'tmaxval',model.tmaxval,...
    'yintval',model.yintval,'slopeval',model.slopeval);
optim.numparams = numparams;
optim.cost = cost;
optim.R2 = 1 - (cost/SSt);
n = nnz(~isnan(data(:)));
optim.BICrel = (n * log(cost/n)) + (numparams *log(n));

    function cost = optim_cost(X,data,model)
        model = unloadX(X,model);
        cost = pret_cost(data,samplerate,model.window,model,pret_cost_options);  
    end

    function stop = fmincon_outfun(X,optimValues,state)
        stop = false;
        switch state
            case 'iter'
                clf
                model = unloadX(X,model);
                gobj1 = plot(time,data','k','LineWidth',1.5);
                [~, gobj2] = pret_plot_model(model);
                legend([gobj1(1) gobj2],{'data' 'model'})
                yl = ylim;
                xl = xlim;
                R2 = 1 - (optimValues.fval/SSt);
                text((xl(2)-xl(1))*.1+xl(1),(yl(2)-yl(1))*.95+yl(1),['Evals: ' num2str(optimValues.funccount)],'HorizontalAlignment','center','BackgroundColor',[0.7 0.7 0.7]);
                text((xl(2)-xl(1))*.1+xl(1),(yl(2)-yl(1))*.88+yl(1),['R^2: ' num2str(R2)],'HorizontalAlignment','center','BackgroundColor',[0.7 0.7 0.7]);
                pause(0.04)
            case 'interrupt'
                % No actions here
            case 'init'
                fh = figure(1);
            case 'done'
                try
                    close(fh);
                catch
                end
            otherwise
        end
    end

    % reads out parameter values from X and places them into model
    % structure. rescales values to original units. if fitted latencies 
    % have resulted in a change in event order, reorders events to ensure 
    % they occur in a serial order.
    function model = unloadX(X,model)
        numevents = size(model.eventtimes,2);
        numboxes = length(model.boxtimes);
        
        if model.ampflag
            numEA = numevents;
            model.ampvals = X(1:numEA) .* (1/ampfact);
        else
            numEA = 0;
        end
        if model.boxampflag
            numBA = numboxes;
            model.boxampvals = X(numEA+1:numEA+numBA) .* (1/boxampfact);
        else
            numBA = 0;
        end
        if model.latflag
            numL = numevents;
            Btemp = model.ampvals;
            Ltemp = X(numEA+numBA+1:numEA+numBA+numL).*(1/latfact);
            %sort component pupil responses by the order they occur in on
            %the basis of eventtime + latency
            %ensures that sequential pupil responses are ascribed to the
            %proper event by assuming the event-related responses occur in
            %the same order as the events occur
            times = mean(model.eventtimes,1) + Ltemp;
            [timessort,ind] = sort(times);
            Btemp = Btemp(ind);
            model.latvals = timessort - mean(model.eventtimes,1);
            model.ampvals = Btemp;
        else
            numL = 0;
        end
        if model.tmaxflag
            numt = 1;
            model.tmaxval = X(numEA+numBA+numL+1) .* (1/tmaxfact);
        else
            numt = 0;
        end
        if model.yintflag
            numy = 1;
            model.yintval = X(numEA+numBA+numL+numt+1) .* (1/yintfact);
        else
            numy = 0;
        end
        if model.slopeflag
            model.slopeval = X(numEA+numBA+numL+numt+numy+1) .* (1/slopefact);
        end
    end

end
