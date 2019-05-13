function [fh, go] = pret_plot_model(model,options)
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
%       model.tmaxval, model.yintval, and model.slopeval must be provided.
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

[Ycalc, X] = pret_calc(model,pret_calc_options);

X = X + model.yintval;
xl = model.window;
onsets = model.eventtimes + model.latvals;
if any(onsets < model.window(1))
    xl(1) = min(onsets(onsets < model.window(1))) - diff(model.window)/10;
end
if any(onsets > model.window(2))
    xl(2) = max(onsets(onsets > model.window(2))) + diff(model.window)/10;
end

fh = gcf;
hold on
plot(time,model.slopeval*time + model.yintval,'k','LineWidth',1);
go = plot(time,Ycalc,'--','color',[0.7 0.7 0.7],'LineWidth',1.5);
ax = gca;
ax.ColorOrderIndex = 1;
plot(time,X,'LineWidth',1.5)
plot([model.window(1) model.window(2)],[model.yintval model.yintval],'k','LineWidth',1);
xlim(xl)
yl = ylim;
ax.ColorOrderIndex = 1;
plot(repmat(onsets,2,1),repmat([yl(1) ; yl(2)],1,length(model.eventtimes)),'--','LineWidth',1);
ax.FontSize = 12;
xlabel('Time (ms)','FontSize',16)
ylabel('Pupil area (percent change)','FontSize',16)
legend([go],{'model'})
