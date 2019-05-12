function [Ycalc, X] = pret_calc(model,options)
% pret_calc
% [Ycalc, X] = pret_calc(model)
% [Ycalc, X] = pret_calc(model,options)
% [Ycalc, X] = pret_calc(optim,options)
% options = pret_calc()
% 
% Calculates the time series and its constituent regresssors resulting from the 
% model parameters and specifications in the given model structure.
% 
%   Inputs:
%   
%       model = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, model.yintval, and model.slopeval must be provided.
%           *Note - an optim/estim structure from pret_estimate, pret_bootstrap, or
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
%       X = 2D matrix of regressors that are summed together and with the
%       y-intercept parameter to create Ycalc. 1st dimension is regressor
%       and 2nd dimension is time.
% 
%   Options
%
%       n = parameter used to generate pupil response function. Canonical
%       value of 10.1 is the default. See the function "pupilrf" and 
%       Hoeks&Levelt 1993 for more information.
% 
%       pret_model_check = options for pret_model_check
%
%   Jacob Parker and Rachel Denison, 2019

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
pret_model_check_options = options.pret_model_check;

%check inputs
if ~isfield(model,'ampflag')
    fprintf('Treating input "model" as an optim/estim structure\n')
    optim_check(model)
else
    pret_model_check(model,pret_model_check_options)
end

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
    temp = (temp/max(temp)) .* model.boxampvals(bx);
    X2(bx,:) = temp(1:length(time));
    
end

X = [X1 ; X2];
Ycalc = sum(X,1) + model.slopeval*time + model.yintval;

    function optim_check(model)
        %window
        if length(model.window) ~= 2
            error('model.window must be a two element vector')
        end
        
        %samplerate
        if length(model.samplerate) ~= 1
            error('model.samplerate must be provided as a single value')
        end
        
        sfact = model.samplerate/1000;
        time = model.window(1):1/sfact:model.window(2);
        if ~(any(model.window(1) == time)) || ~(any(model.window(2) == time))
            error('"model.window" not compatible with "model.samplerate"')
        end
        
        %event amplitude
        if length(model.eventtimes) ~= length(model.ampvals)
            error('Number of defualt event amplitudes not equal to number of events')
        end
        
        %box amplitude
        if ~isempty(model.boxtimes)
            for ii = 1:length(model.boxtimes)
                if length(model.boxtimes{ii}) ~= 2
                    error('All cells in boxtimes must be a 2 element vector')
                end
            end
        end
        if length(model.boxtimes) ~= length(model.boxampvals)
            error('Number of defualt box amplitudes not equal to number of boxes')
        end
        
        %latency
        if length(model.eventtimes) ~= length(model.latvals)
            error('Number of defualt event latency not equal to number of events')
        end
        
        %tmax
        if length(model.tmaxval) ~= 1
            error('Number of default tmax values not equal to 1')
        end
        
        %y-intercept
        if length(model.yintval) ~= 1
            error('Number of default y-intercept values not equal to 1')
        end
        
        %slope
        if length(model.slopeval) ~= 1
            error('Number of default slope values not equal to 1')
        end
    end

end

