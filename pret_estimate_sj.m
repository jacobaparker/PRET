function sj = pret_estimate_sj(sj,model,wnum,options)
% pret_estimate_sj
% sj = pret_estimate_sj(sj,models)
% sj = pret_estimate_sj(sj,models,options)
% 
% Performs the parameter estimation procedure for each set of data that has
% been preprocessed/organized into a sj structure by pret_preprocess.
% 
%   Inputs:
%
%       sj = structure output by pret_preprocess containing data in a format
%       that pret_estimate_sj uses.
% 
%       model = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, and model.yintval do not need to be provided if they
%       are being estimated but should be provided if they are not being estimated.
%           *NOTE - if you want to fit multiple models, you can input an
%           Nx1 structure with the same fields as "model", where N is the
%           number of models and each element is a separate model
%           structure*
% 
%       wnum = number of workers used by matlab's parallel pool to complete
%       the process (parpool will not be initialized if set to 1).
% 
%       options = options structure for pret_estimate_sj. Default options can be
%       returned by calling this function with no arguments, or see
%       pret_default_options.
%
%   Output
%
%       sj = same structure that was input, but with the additional field
%       appended:
%           optim = a structure with fields titled after the condition
%           labels. Each of these fields is an 1xN structure, where N is
%           the number of models in the "model" input. Each element in
%           these structures is an optim structure output by pret_estimate
%           fitting that condition with a single model. For more
%           information about this structure, see pret_estimate.
%
%   Options
%
%       pret_estimate_options = options structure for pret_estimate, 
%       which pret_estimate_sj uses to perform parameter estimation for each
%       set of data in sj.
%
%   Jacob Parker 2018

if nargin < 4
    opts = pret_default_options();
    options = opts.pret_estimate_sj;
    clear opts
    if nargin < 1
        sj = options;
        return
    end
end

%OPTIONS
pret_estimate_options = options.pret_estimate; 

%check model
for mm = 1:length(model)
    try
        pret_model_check(model(mm))
    catch
        fprintf('\nError in model %d\n',mm)
        pret_model_check(model(mm))
    end
end

sj.estim = [];

for mm = 1:length(model)
    fprintf('\nModel %d\n',mm)
    for cc = 1:length(sj.conditions)
        cond = sj.conditions{cc};
        fprintf('Condition %s\n',cond)
        sj.estim.(cond)(mm) = pret_estimate(sj.means.(cond), ...
            sj.samplerate, sj.trialwindow, model(mm), wnum, pret_estimate_options);
    end
end