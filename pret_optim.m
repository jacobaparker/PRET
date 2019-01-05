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
%       data = a single pupil size time series as a row vector.
% 
%       samplerate = sampling rate of data in Hz.
% 
%       trialwindow = a 2 element vector containing the starting and ending
%       times (in ms) of the trial epoch.
% 
%       model = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, and model.yintval MUST be provided. These values are
%       the starting point for the optimization.
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
%           %%% RD: add BIC?
%       *Note - can be input into pret_plot_model and pret_calc in the 
%       place of the "model" input*
% 
%   Options
%
%       optim_plot_flag (true/false) = plot optimization in realtime? Set
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
%       yintfact (10) = scaling factor fo the yint parameter.
% 
%       A, B, Aeq, Beq, NONLCON, fmincon_options = optional input arguments
%       into fmincon. See documentation for fmincon for more details.
%
%   Jacob Parker 2018

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

%Factors to scale parameters by so that they are of a similar magnitude.
%Improves performance of the constrained optimization algorithm (fmincon)
ampfact = options.ampfact;
boxampfact = options.boxampfact;
latfact = options.latfact;
tmaxfact = options.tmaxfact;
yintfact = options.yintfact;
slopefact = options.slopefact;

%input values/options for fmincon
A = options.A;
B = options.B;
Aeq = options.Aeq;
Beq = options.Beq;
NONLCON = options.NONLCON;
fmincon_options = options.fmincon_options;

modelstate = model;
sfact = samplerate/1000;
time = trialwindow(1):1/sfact:trialwindow(2);

%check inputs
pret_model_check(model)

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

%crop data to match model.window
datalb = find(model.window(1) == time);
dataub = find(model.window(2) == time);
data = data(datalb:dataub);

%recalculate time point vector
time = model.window(1):1/sfact:model.window(2);

%construct inputs into fmincon (X, bounds, etc)
%MAKE SURE WORKS WITH CURRENT MODEL STRUCTURE
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

f = @(X)optim_cost(X,data,model);

if optimplotflag
    fmincon_options.OutputFcn = @fmincon_outfun;
end

modelstate = model;
SSt = sum((data-nanmean(data)).^2);

[X, cost] = fmincon(f,X,A,B,Aeq,Beq,lb,ub,NONLCON,fmincon_options);

modelstate = unloadX(X,modelstate);
optim = struct('eventtimes',model.eventtimes,'boxtimes',{model.boxtimes},'samplerate',model.samplerate,'window',model.window,'ampvals',modelstate.ampvals,'boxampvals',modelstate.boxampvals,'latvals',modelstate.latvals,'tmaxval',modelstate.tmaxval,'yintval',modelstate.yintval,'slopeval',modelstate.slopeval);
optim.numparams = numparams;
optim.cost = cost;
optim.R2 = 1 - (cost/SSt);
optim.BIC = (length(data) * log(cost/length(data))) + (numparams *log(length(data)));

    function cost = optim_cost(X,data,modelstate)
        modelstate = unloadX(X,modelstate);
        cost = pret_cost(data,samplerate,modelstate.window,modelstate,pret_cost_options);  
    end

    function stop = fmincon_outfun(X,optimValues,state)
        stop = false;
        switch state
            case 'iter'
                clf
                modelstate = unloadX(X,modelstate);
                plot(time,data,'k','LineWidth',1.5)
                pret_plot_model(modelstate);
                yl = ylim;
                xl = xlim;
                R2 = 1 - (optimValues.fval/SSt);
                text((xl(2)-xl(1))*.1,yl(2)*.95,['Evals: ' num2str(optimValues.funccount)],'HorizontalAlignment','center','BackgroundColor',[0.7 0.7 0.7]);
                text((xl(2)-xl(1))*.1,yl(2)*.85,['R^2: ' num2str(R2)],'HorizontalAlignment','center','BackgroundColor',[0.7 0.7 0.7]);
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

    function modelstate = unloadX(X,modelstate)
        numevents = length(modelstate.eventtimes);
        numboxes = length(modelstate.boxtimes);
        
        if modelstate.ampflag
            numEA = numevents;
            modelstate.ampvals = X(1:numEA) .* (1/ampfact);
        else
            numEA = 0;
        end
        if modelstate.boxampflag
            numBA = numboxes;
            modelstate.boxampvals = X(numEA+1:numEA+numBA) .* (1/boxampfact);
        else
            numBA = 0;
        end
        if modelstate.latflag
            numL = numevents;
            Btemp = modelstate.ampvals;
            Ltemp = X(numEA+numBA+1:numEA+numBA+numL).*(1/latfact);
            %sort component pupil responses by the order they occur in on
            %the basis of eventtime + latency
            %ensures that sequential pupil responses are ascribed to the
            %proper event by assuming the event-related responses occur in
            %the same order as the events occur
            [~,ind] = sort(modelstate.eventtimes + Ltemp);
            Ltemp = Ltemp(ind);
            Btemp = Btemp(ind);
            modelstate.latvals = Ltemp;
            modelstate.ampvals = Btemp;
        else
            numL = 0;
        end
        if modelstate.tmaxflag
            numt = 1;
            modelstate.tmaxval = X(numEA+numBA+numL+1) .* (1/tmaxfact);
        else
            numt = 0;
        end
        if modelstate.yintflag
            numy = 1;
            modelstate.yintval = X(numEA+numBA+numL+numt+1) .* (1/yintfact);
        else
            numy = 0;
        end
        if modelstate.slopeflag
            modelstate.slopeval = X(numEA+numBA+numL+numt+numy+1) .* (1/slopefact);
        end
    end

end
