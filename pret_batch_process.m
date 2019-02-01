function sjs = pret_batch_process(sjs,models,nboots,wnum,options)
% pret_batch_process
% sjs = pret_batch_process(sjs,models,nboots,wnum)
% sjs = pret_batch_process(sjs,models,nboots,wnum,options)
% 
% Performs the estimation procedure and/or the bootstrapping procedure to
% estimate model parameters for the data for each sj structure in sjs.
% 
%   Inputs:
%
%       sjs = structure in which each field is an sj structure output by
%       pret_preprocess.
% 
%       models = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, model.yintval, and model.slopeval do NOT need to be 
%       provided (unless any of those parameters are not being estimated).
%           *NOTE - if you want to fit multiple models, you can input an
%           Nx1 structure with the same fields as "model", where N is the
%           number of models and each element is a separate model
%           structure*
% 
%       nboots = if doing bootstrapping procedure, how many bootstrap
%       iterations to do. Can be empty if not.
% 
%       wnum = how many Matlab workers to use if doing the estimation
%       and/or bootstrapping procedures.
% 
%       options = options structure for pret_batch_process. Default options can be
%       returned by calling this function with no arguments, or see
%       pret_default_options.
%
%   Output
%
%       sjs = same structure that was input, but with the following fields
%       appended to each sj structure (the fields of sjs):
%           *if estimation done*
%           optim = a Nx1 structure, where N is the number of models input
%           in "model". Each element of this structure is an optim
%           structure for a single model. See pret_optim or pret_estimate for
%           more information about this structure.
%           *if bootstrapping done*
%           boots = a Nx1 structure, where N is the number of models input
%           in "model". Each element of this structure is an boots
%           structure for a single model. See pret_bootstrap for more
%           information about this structure.
%
%   Options
% 
%       estflag (true/false) = do estimation procedure on the data in each
%       sj structure? Implemented by pret_estimate_sj.
% 
%       bootflag (true/false) = do bootstrapping procedure on the data in each
%       sj structure? Implemented by pret_boostrap_sj.
% 
%       pret_estimate_sj_options = options structure for pret_estimate_sj, 
%       which pret_batch_process uses to perform parameter estimation for the
%       data in each sj structure.
% 
%       pret_bootstrap_sj_options = options structure for pret_bootstrap_sj, 
%       which pret_batch_process uses to perform the bootstrapping procedure for the
%       data in each sj structure.
% 
%       pret_model_check = options for pret_model_check
%
%   Jacob Parker and Rachel Denison, 2019

if nargin < 5
    opts = pret_default_options();
    options = opts.pret_batch_process;
    clear opts
    if nargin < 1
        sjs = options;
        return
    end
end

%OPTIONS
estflag = options.estflag;
bootflag = options.bootflag;
pret_estimate_sj_options = options.pret_estimate_sj;
pret_bootstrap_sj_options = options.pret_bootstrap_sj;
pret_model_check_options = options.pret_model_check;

check models
for mm = 1:length(model)
    try
        pret_model_check(model(mm),pret_model_check_options)
    catch
        fprintf('\nError in model %d\n',mm)
        pret_model_check(model(mm),pret_model_check_options)
    end
end

sjfields = fieldnames(sjs);

for s = 1:length(sjfields)
    fprintf('Subject %s\n',sjfields{s})
    if estflag
        sjs.(sjfields{s}) = pret_estimate_sj(sjs.(sjfields{s}),models,wnum,pret_estimate_sj_options);
    end
    if bootflag
        sjs.(sjfields{s}) = pret_bootstrap_sj(sjs.(sjfields{s}),models,nboots,wnum,pret_bootstrap_sj_options);
    end
end
    