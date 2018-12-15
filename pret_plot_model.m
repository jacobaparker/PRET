function fh = pret_plot_model(model,options)
% pret_plot_model(model)
% pret_plot_model(model,options)
% 
% Plots the time series and its constituent regresssors resulting from the 
% model parameters and specifications in the given model structure.
% 
%   Inputs:
%       
%       model = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, and model.yintval must be provided.
%           *Note - an estim/optim structure from pret_estimate, pret_bootstrap, or
%           pret_optim can be input in the place of model*
% 
%       options = options structure for pret_calc. Default options can be
%       returned by calling this function with no arguments.
% 
%   Outputs:
% 
%       fh = figure handle for the resulting figure.
% 
%   Options:
% 
%       pret_calc_options = options structure for pret_calc, which
%       pret_plot_model uses to calculate the model time series and
%       regressors that are plotted.
% 
% Jacob Parker 2018

if nargin < 2
    opts = pret_default_options();
    options = opts.pret_plot_model;
    clear opts
    if nargin < 1
        fh = options;
        return
    end
end

%OPTIONS
pret_calc_options = options.pret_calc;

sfact = model.samplerate/1000;
time = model.window(1):1/sfact:model.window(2);

%check inputs
if ~isfield(model,'ampflag')
    fprintf('Input "model" does not appear to be a model structure, assuming it is an optim/estim structure\n')
    optim_check(model)
else
    pret_model_check(model)
end

[Ycalc, X] = pret_calc(model,pret_calc_options);

X = X + model.yintval;

fh = gcf;
hold on
plot(time,Ycalc,'--','color',[0.6 0.6 0.6],'LineWidth',1.5)
ax = gca;
ax.ColorOrderIndex = 1;
plot(time,X,'LineWidth',1.5)
plot([model.window(1) model.window(2)],[model.yintval model.yintval],'k','LineWidth',1);
xlim(model.window)
yl = ylim;
ax.ColorOrderIndex = 1;
plot(repmat(model.eventtimes + model.latvals,2,1),repmat([yl(1) ; yl(2)],1,length(model.eventtimes)),'--','LineWidth',1)
ax.FontSize = 12;
xlabel('Time (ms)','FontSize',16)
ylabel('Pupil area (proportion change)','FontSize',16)

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
                if ~(any(model.boxtimes{ii}(1) == time)) || ~(any(model.boxtimes{ii}(2) == time))
                    error('Box %d start and end time points do not fall on time vector defined by\nmodel.window and model.samplerate',ii)
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
    end

end
