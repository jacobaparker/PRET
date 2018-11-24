function sj = pret_preprocess(data,samplerate,trialwindow,condlabels,baseline,options)
% pret_preprocess
% sj = pret_preprocess(data,trialwindow,samplerate,baseline)
% sj = pret_preprocess(data,trialwindow,samplerate,baseline,options)
%
% Prepare pupil area time series data for use with PRF linear model.
%
%   Inputs:
%
%       data = a cell array containing one 2D matrix of epoched pupil size
%       time series data for each separate condition. These matrices are
%       assumed to be in the form (trial number)X(time).
%
%       samplerate = sampling rate of data in Hz.
%
%       trialwindow = a 2 element vector containing the starting and ending
%       times (in ms) of the trial epoch.
%
%       condlabels = a cell array of condition labels for the data. 
%
%       baseline = a 2 element vector containing the starting and ending
%       times (in ms) of the region to be used to baseline normalize each
%       trial (can be empty if normalization turned off).
% 
%       options = 
%
%   Output
%
%       sj = structure containing preprocessed data ready to be estimated
%       with a pupil response function linear model. Contains the following
%       fields:
%           samplerate = a copy of the input samplerate.
%           trialwindow = a copy of the input trialwindow.
%           conditions = a copy of the input condition labels.
%           baseline = a copy of the input baseline, if normalization was
%           done.
%           <condition names> = there will be a field entitled after every
%           entry in condlabels. Each of these contains the preprocessed,
%           epoched trials for that condition (as long as the order
%           matches!).
%           means = a structure containing the mean for each condition
%           under their own field names.
%
%   Options
%
%       normflag: (true/false) = baseline normalize epoched trials?
%       [(x-baseline)/baseline], where x is the trial and baseline is the
%       average pupil size value over the baseline region provided.
% 
%       blinkflag: (true/false) = perform blink interpolation of each trial?
%       Uses a cubic spline interpolation algorithm described by Math�t
%       2013, implemented in the function "blinkinterp".
% 
%       th1, th2, bwindow, and betblink = input arguments for the blink
%       interpolation function. See the function "blinkinterp" for
%       explanation.
%
%   Jacob Parker 2018

if nargin < 6
    opts = pret_default_options();
    options = opts.pret_preprocess;
    clear opts
    if nargin < 1
        sj = options;
        return
    end
end

%OPTIONS
normflag = options.normflag;
blinkflag = options.blinkflag;

%blinkinterp arguments
th1 = options.th1;
th2 = options.th2;
bwindow = options.bwindow;
betblink = options.betblink;

sfact = samplerate/1000;
time = trialwindow(1):1/sfact:trialwindow(2);

%check input arguments
%trialwindow vs samplerate
if ~(any(time == trialwindow(1)) && any(time == trialwindow(2)))
    error('Trial window not compatible with input sampling rate')
end

%trialwindow vs length of trial
for dd =1:length(data)
    if size(data{dd},2) ~= length(time)
        error('Trial length does not match information input about trial duration according to "trialwindow" and "sample rate"')
    end
end

%condlabels vs data
if length(condlabels) ~= length(data)
    error('Number of trial matrices in "data" does not match number of labels in "condlabels"')
end

% for arg = 1:length(varargin)
%     switch varargin{arg}
%         case 'nonormalize'
%             normflag = false;
%         case 'noblinkinterp'
%             blinkflag = false;
%         case 'blinkinterpargs'
%             th1 = varargin{arg+1}(1);
%             th2 = varargin{arg+1}(2);
%             bwindow = varargin{arg+1}(3);
%             betblink = varargin{arg+1}(4);
%     end
% end

%preallocate output structure sj
sj = struct('samplerate',samplerate,'trialwindow',trialwindow,'conditions',{condlabels});
datatemp = cell(1,length(data));
for cc = 1:length(condlabels)
    sj.(condlabels{cc}) = nan(size(data{cc},1),size(data{cc},2));
    datatemp{cc} = data{cc};
end

%blink interpolation
if blinkflag
    for dd = 1:length(datatemp)
        for tt = 1:size(datatemp{dd},1)
            datatemp{dd}(tt,:) = blinkinterp(datatemp{dd}(tt,:),samplerate,th1,th2,bwindow,betblink);
        end
    end
end

%normalization
if normflag
    if length(baseline) ~= 2
        error('"baseline" argument must be a two element vector')
    end
    sj.baseline = baseline;
    %baseline vs trialwindow
    if baseline(1) < trialwindow(1) || baseline(2) > trialwindow(2)
        error('Baseline region falls outside of trial window')
    end
    %does baseline actually match up with time points (time vector)?
    if ~(any(time == baseline(1)) && any(time == baseline(2)))
        error('Trial window not congruent with input sampling rate')
    end
    
    for dd = 1:length(datatemp)
        base = nanmean(datatemp{dd}(:,(-trialwindow(1)*sfact)+(baseline(1)*sfact)+1:(-trialwindow(1)*sfact)+(baseline(2)*sfact)),2);
        for tt = 1:size(datatemp{dd},1)
            datatemp{dd}(tt,:) = (datatemp{dd}(tt,:)-base(tt))/base(tt);
        end
    end
end

%finish filling output structure sj
sj.means = [];
for cc = 1:length(condlabels)
    sj.(condlabels{cc}) = datatemp{cc};
    sj.means.(condlabels{cc}) = nanmean(datatemp{cc},1);
end
