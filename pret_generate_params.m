function params = pret_generate_params(num,parammode,model,options)
% pret_generate_params
% params = pret_generate_params(num, parammode, model)
% params = pret_generate_params(num, parammode, model,options)
% options = pret_generate_params()
% 
% Generates random parameters using the specifications of a given model.
% 
%   Inputs:
%   
%       num = number of sets of parameters to be generated.
% 
%       parammode ('uniform', 'normal', or 'space_optimal') = mode used to
%       generate parameters.
%           'uniform' - parameters are attempted to be sampled evenly
%           from the range of their respective bounds. When the number of 
%           points sampled is relatively low, binning can help span the 
%           parameter space. For each parameter, the range is split up 
%           into options.nbins number of bins and a floor(num/nbins) number 
%           of points is randomly and uniformly sampled from each bin. The 
%           remaining points are then sampled from the entire range. 
%           'normal' - parameters are drawn from a normal distrubtion
%           centered around the values provided in the input model
%           structure. The standard deviation is set by options.sigma.
% 
%       model = model structure created by pret_model and filled in by user.
%           *IMPORTANT - parameter values in model.ampvals,
%           model.boxampvals, model.latvals, model.tmaxval, model.yintval, 
%           and model.slopeval must be provided if 'normal' parammode is used!
% 
%       options = options structure for pret_generate_params. Default options 
%       can be returned by calling this function with no arguments, or see
%       pret_default_options.
% 
%   Outputs:
% 
%      params = an output structure containing all sets of parameters
%      generated. Contains the following fields:
%           ampvals = 2D matrix of generated event amplitude parameters.
%           Each row is one set of parameters.
%           boxampvals = 2D matrix of generated box amplitude parameters.
%           latvals = 2D matrix of generated event latency parameters.
%           tmaxvals = column vector of generated tmax parameters.
%           yintvals = column vector of generated y-intercept parameters.
%           slopevals = column vector of generated slope parameters.
%           
% 
%   Options
% 
%       nbins (50) = if 'uniform' parammode is used, specifies the number of
%       bins that are sampled from across the range of each parameter.
% 
%       sigma (0.05) = if 'normal' parammode is used, specifies the standard
%       deviation of the normal distribution each parameter is drawn from.
%       This standard deviation is applied differentially to each parameter
%       using their respective scaling factors (below).
% 
%       ampfact (1/10), boxampfact (1/10), latfact (1/1000), tmaxfact (1/1000), 
%       yintfact (1/10), slopefact (100) = if 'normal' parammode is used, 
%       these options specify the scaling factors for amplitude, latency, 
%       tmax, y-intercept, and slope parameters respectively. This is
%       necessary to apply a single sigma value to different parameters
%       that have varying orders of magntitude.
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
    options = opts.pret_generate_params;
    clear opts
    if nargin < 1
        params = options;
        return
    end
end

%OPTIONS
nbins = options.nbins;
sigma = options.sigma;
ampfact = options.ampfact;
boxampfact = options.boxampfact;
latfact = options.latfact;
tmaxfact = options.tmaxfact;
yintfact = options.yintfact;
slopefact = options.slopefact;
pret_model_check_options = options.pret_model_check;

%check inputs
pret_model_check(model,pret_model_check_options)

if ~((round(num) == num) && num > 0)
    error('Input "num" must be positive integer')
end

%set random number generator
rng(0)

params = struct('blank',[]);

params.ampvals = nan(num,length(model.eventtimes));
params.latvals = nan(num,length(model.eventtimes));
params.tmaxvals = nan(num,1);
params.yintvals = nan(num,1);
params.slopevals = nan(num,1);
params.boxampvals = nan(num,length(model.boxtimes));

params = rmfield(params,'blank');

switch parammode
    case 'uniform'
        
        %amplitude
        if model.ampflag
            for cc = 1:length(model.eventtimes)
                params.ampvals(:,cc) = unibin(num,model.ampbounds(1,cc),model.ampbounds(2,cc),nbins);
            end
        else
            params.ampvals = repmat(model.ampvals,num,1);
        end
        
        %latency
        if model.latflag
            for cc = 1:length(model.eventtimes)
                params.latvals(:,cc) = unibin(num,model.latbounds(1,cc),model.latbounds(2,cc),nbins);
            end
        else
            params.latvals = repmat(model.latvals,num,1);
        end
        
        %tmax
        if model.tmaxflag
            params.tmaxvals = unibin(num,model.tmaxbounds(1),model.tmaxbounds(2),nbins);
        else
            params.tmaxvals = repmat(model.tmaxval,num,1);
        end
        
        %y-intercept
        if model.yintflag
            params.yintvals = unibin(num,model.yintbounds(1),model.yintbounds(2),nbins);
        else
            params.yintvals = repmat(model.yintval,num,1);
        end
        
        %slope
        if model.slopeflag
            params.slopevals = unibin(num,model.slopebounds(1),model.slopebounds(2),nbins);
        else
            params.slopevals = repmat(model.slopeval,num,1);
        end
        
        %box amplitude
        if model.boxampflag
            for cc = 1:length(model.boxtimes)
                params.boxampvals(:,cc) = unibin(num,model.boxampbounds(1,cc),model.boxampbounds(2,cc),nbins);
            end
        else
            params.boxampvals = repmat(model.boxampvals,num,1);
        end
        
    case 'normal'
        
        if model.ampflag
            ampvals = model.ampvals .* ampfact;
            for cc = 1:length(model.eventtimes)
                params.ampvals(:,cc) = (ampvals(cc) + randn(num,1) .* sigma) .* 1/ampfact;
            end
            params.ampvals(params.ampvals < model.ampbounds(1,cc)) = model.ampbounds(1,cc);
            params.ampvals(params.ampvals > model.ampbounds(2,cc)) = model.ampbounds(2,cc);
        else
            params.ampvals = repmat(model.ampvals,num,1);
        end
        
        if model.latflag
            latvals = model.latvals .* latfact;
            for cc = 1:length(model.eventtimes)
                params.latvals(:,cc) = (latvals(cc) + randn(num,1) .* sigma) .* 1/latfact;
            end
            params.latvals(params.latvals < model.latbounds(1,cc)) = model.latbounds(1,cc);
            params.latvals(params.latvals > model.latbounds(2,cc)) = model.latbounds(2,cc);
        else
            params.latvals = repmat(model.latvals,num,1);
        end
        
        if model.tmaxflag
            tmaxval = model.tmaxval .* tmaxfact;
            params.tmaxvals = (tmaxval + randn(num,1) .* sigma) .* 1/tmaxfact;
            params.tmaxvals(params.tmaxvals < model.tmaxbounds(1)) = model.tmaxbounds(1);
            params.tmaxvals(params.tmaxvals > model.tmaxbounds(2)) = model.tmaxbounds(2);
        else
            params.tmaxvals = repmat(model.tmaxval,num,1);
        end
        
        if model.yintflag
            yintval = model.yintval .* yintfact;
            params.yintvals = (yintval + randn(num,1) .* sigma) .* 1/yintfact;
            params.yintvals(params.yintvals < model.yintbounds(1)) = model.yintbounds(1);
            params.yintvals(params.yintvals > model.yintbounds(2)) = model.yintbounds(2);
        else
            params.yintvals = repmat(model.yintval,num,1);
        end
        
        if model.slopeflag
            slopeval = model.slopeval .* slopefact;
            params.slopevals = (slopeval + randn(num,1) .* sigma) .* 1/slopefact;
            params.slopevals(params.slopevals < model.slopebounds(1)) = model.slopebounds(1);
            params.slopevals(params.slopevals > model.slopebounds(2)) = model.slopebounds(2);
        else
            params.slopevals = repmat(model.slopeval,num,1);
        end
        
        if model.boxampflag
            boxampvals = model.boxampvals .* boxampfact;
            for cc = 1:length(model.boxtimes)
                params.boxampvals(:,cc) = (boxampvals(cc) + randn(num,1) .* sigma) .* 1/boxampfact;
            end
            params.boxampvals(params.boxampvals < model.boxampbounds(1,cc)) = model.boxampbounds(1,cc);
            params.boxampvals(params.boxampvals > model.boxampbounds(2,cc)) = model.boxampbounds(2,cc);
        else
            params.boxampvals = repmat(model.boxampvals,num,1);
        end
        
    otherwise
        error('Input "parammode" not recognized.')
end

    function dist = unibin(num,lb,ub,nbins)
        %generates a kind of uniform distrubution of num numbers by defining a range,
        %splitting that range into nbins number of bins, then using rand to
        %generate floor(num/nbins) in each bin. The remainder of this
        %division is sampled from across the entire range.
        pbb = floor(num/nbins);
        rmn = rem(num,nbins);
        temp = nan(num,1);
        bins = linspace(lb,ub,nbins+1);
        for b = 1:nbins
            temp(pbb*(b-1)+1:pbb*b) = (bins(b+1)-bins(b)).*rand(pbb,1) + bins(b);
        end
        if rmn ~= 0
            temp(num-rmn+1:num) = (ub-lb).*rand(rmn,1) + lb;
        end
        dist = randsample(temp,num);
    end

end
    