function sj = pret_bootstrap_sj(sj,model,nboots,wnum,options)
% pret_bootstrap_sj
% sj = pret_bootstrap_sj(sj,model,nboots,wnum)
% sj = pret_bootstrap_sj(sj,model,nboots,wnum,options)
% options = pret_bootstrap_sj()
% 
% Performs the bootstrapping procedure for estimating model parameters on
% each set of data that has been preprocessed/organized into a sj structure
% by pret_preprocess.
% 
%   Inputs:
%
%       sj = structure output by pret_preprocess containing data in a format
%       that pret_estimate_sj uses.
% 
%       model = model structure created by pret_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, model.yintval, and model.slopeval need to be
%       provided only if they are not being estimated.
%           *NOTE - if you want to fit multiple models, you can input an
%           Nx1 structure with the same fields as "model", where N is the
%           number of models and each element is a separate model
%           structure*
% 
%       wnum = number of workers used by matlab's parallel pool to complete
%       the process (parpool will not be initialized if set to 1).
% 
%       options = options structure for pret_bootstrap_sj. Default options can be
%       returned by calling this function with no arguments, or see
%       pret_default_options.
%
%   Output
%
%       sj = same structure that was input, but with the additional field
%       appended:
%           boots = a Nx1 structure, where N is the number of models input
%           in "model". Each element of this structure is an boots
%           structure for a single model. See pret_bootstrap for more
%           information about this structure.
%
%   Options
%
%       pret_bootstrap_options = options structure for pret_bootstrap, 
%       which pret_bootstrap_sj uses to perform parameter estimation for each
%       set of data in sj.
% 
%       saveflag (true/false) = save a .mat file with the output sj
%       variable?
% 
%       savefile = if saveflag true, save .mat file to this dir (include
%       name of course)
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
    options = opts.pret_bootstrap_sj;
    clear opts
    if nargin < 1
        sj = options;
        return
    end
end

%OPTIONS
pret_bootstrap_options = options.pret_bootstrap;
saveflag = options.saveflag;
savefile = options.savefile;
pret_model_check_options = options.pret_model_check;

%check models
for mm = 1:length(model)
    try
        pret_model_check(model(mm),pret_model_check_options)
    catch
        fprintf('\nError in model %d\n',mm)
        pret_model_check(model(mm),pret_model_check_options)
    end
end

sj.boots = [];

for mm = 1:length(model)
    fprintf('\nModel %d',mm)
    for cc = 1:length(sj.conditions)
        fprintf('\nCondition %s\n',sj.conditions{cc})
        sj.boots(mm).(sj.conditions{cc}) = pret_bootstrap(sj.(sj.conditions{cc}),sj.samplerate,sj.trialwindow,model(mm),nboots,wnum,pret_bootstrap_options);
    end
    if saveflag
        save(savefile,'sj')
    end
end