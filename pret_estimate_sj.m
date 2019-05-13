function sj = pret_estimate_sj(sj,model,wnum,options)
% pret_estimate_sj
% sj = pret_estimate_sj(sj,models,wnum)
% sj = pret_estimate_sj(sj,models,wnum,options)
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
%       model.tmaxval, model.yintval, and model.slopeval do not need to be 
%       provided if they are being estimated but should be provided if they 
%       are not being estimated.
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
%       trialmode = 'mean' to fit the trial means or 'single' to fit single 
%       trials simultaneously (default = 'mean')
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
trialmode = options.trialmode;
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

sj.estim = [];

for mm = 1:length(model)
    fprintf('\nModel %d\n',mm)
    for cc = 1:length(sj.conditions)
        cond = sj.conditions{cc};
        fprintf('Condition %s\n',cond)
        switch trialmode
            case 'mean'
                data = sj.means.(cond);
            case 'single'
                data = sj.(cond);
            otherwise
                error('"trialmode" not recognized')
        end
        sj.estim(mm).(cond) = pret_estimate(data, ...
            sj.samplerate, sj.trialwindow, model(mm), wnum, pret_estimate_options);
        
        if saveflag
            save(savefile,'sj')
        end
    end
end