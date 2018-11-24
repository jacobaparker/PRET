function [Ycalc, X] = pret_calc(model,options)
% pret_calc
% [Ycalc, X] = pret_calc(model)
% [Ycalc, X] = pret_calc(model,options)
% [Ycalc, X] = pret_calc(optim,options)
% 
% Calculates the time series and its constituent regresssors resulting from the 
% model parameters and specifications in the given model structure.
% 
%   Inputs:
%   
%       model = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, and model.yintval must be provided.
%           *Note - an optim structure from pret_estimate, pret_bootstrap, or
%           pret_optim can be input in the place of model*
% 
%       options = options structure for pret_calc. Default options can be
%       returned by calling this function with no arguments.
% 
%   Outputs:
% 
%       Ycalc = time series created using the parameters and specifications
%       provided in the model input.
% 
%       X = 2D matrix of regressors summed together and with the
%       y-intercept parameter to create Ycalc. 1st dimension is regressor
%       and 2nd dimension is time.
% 
%   Options
%
%       n = parameter used to generate pupil response function. Canonical
%       value of 10.1 is the default. See the function "pupilrf" and 
%       Hoeks&Levelt 1993 for more information.
%
%   Jacob Parker 2018

if nargin < 2
    opts = pret_default_options();
    options = opts.pret_calc;
    clear opts
    if nargin < 1
        Ycalc = options;
        return
    end
end

%OPTIONS
n = options.n;

%check input
pret_model_check(model)

sfact = model.samplerate/1000;
time = model.window(1):1/sfact:model.window(2);

X1 = nan(length(model.eventtimes),length(time));
X2 = nan(length(model.boxtimes),length(time));

for xx = 1:size(X1,1)
    
    h = pupilrf(time,n,model.tmaxval,model.eventtimes(xx)+model.latvals(xx));
    temp = conv(h,model.ampvals(xx));
    X1(xx,:) = temp;
    
end

for bx = 1:size(X2,1)
    
    h = pupilrf(time,n,model.tmaxval,model.boxtimes{bx}(1));
    temp = conv(h,(ones(1,(model.boxtimes{bx}(2)-model.boxtimes{bx}(1))*sfact+1)));
    temp = (temp/max(temp)) .* 0.01 .* model.boxampvals(bx);
    X2(bx,:) = temp(1:length(time));
    
end

X = [X1 ; X2];
Ycalc = sum(X,1) + model.yintval;

