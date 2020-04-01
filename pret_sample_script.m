%% pret_sample_script
% 
% A script demonstrating several functionalities of PRET. It can also be
% used to test if PRET is working properly (it will test almost every
% function in the toolbox).
% 
% If you are working through the script to learn how to use PRET, I suggest
% you run each section one by one. If you are testing your installation of
% PRET, just run the entire thing.
% 
% For more information about the modeling framework presented here, see 
% [insert citation here]
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

%% Define a task (by creating a model)
% Let's preallocate an empty model structure to represent a hypothetical
% task. We are going to use this model to generate artificial data for a
% single "subject".
taskmodel = pret_model();

% Let's assume that we have a sampling frequency of 1000 Hz and that the
% trials will be epoched from -500 to 3500 ms.
taskmodel.window = [-500 3500];
taskmodel.samplerate = 1000;
 
% Now let's suppose the trial sequence of this task is the following:
% 
%   A precue informs the observer that the trial has begun, the observer 
%   sees 2 stimuli 1000 and 1250 ms after the
%   precue, then a postcue 500 ms after the last stimulus instructs the
%   observer to respond. 
% 
% From this, we have 4 events; precue, stimulus 1, stimulus 2, postcue.
% Let's say the precue is time 0 ms, then these events occur at 0 ms, 1000
% ms, 1250 ms, and 1750 ms respectively.
taskmodel.eventtimes = [0 1000 1250 1750];
taskmodel.eventlabels = {'precue' 'stim1' 'stim2' 'postcue'}; %optional

% We also have a response at the end of the trial. For the sake of 
% simplicity, let's say the observer always responds 1000 ms after the 
% postcue. Let's assume that there's a constant internal signal
% due to the cognitive workload associated with completing the task
% and making the decision. This constant internal signal would start at
% precue onset (0 ms) and last until time of response (2750 ms). In the
% context of this model, this would be a box regressor.
taskmodel.boxtimes = {[0 2750]};
taskmodel.boxlabels = {'task'}; %optional

% Now we need to define the structure of the data using the model
% parameters. Let's say that the amplitude and latency of event-related
% pupil responses are expected to vary.
taskmodel.ampflag = true;
taskmodel.latflag = true;

% Let's also say we expect amplitude of the task-related pupil response and
% the tmax of the observer's pupil reponse to vary.
taskmodel.boxampflag = true;
taskmodel.tmaxflag = true;

% Now let's assume the baseline is perfectly stable (the y-intercept would
% always be 0) and that we don't expect any linear drift in pupil size
% during the trial (slope = 0).
taskmodel.yintflag = false;
taskmodel.slopeflag = false;

% Since the y-intercept and slope are always going to be 0, let's put that
% information into the structure.
taskmodel.yintval = 0;
taskmodel.slopeval = 0;

% Let's define boundaries for the parameters we will be fitting. Let's say
% event and box-related amplitudes will all be between 0 and 100 (percent 
% signal change from baseline), event latencies will be between -500 and 
% 500 ms, and tmax will be between 500 and 1500.
taskmodel.ampbounds = repmat([0;100],1,length(taskmodel.eventtimes));
taskmodel.latbounds = repmat([-500;500],1,length(taskmodel.eventtimes));
taskmodel.boxampbounds = [0;100];
taskmodel.tmaxbounds = [500;1500];

% So far, the model's specifications are common to all task conditions. Now
% let's define different models for each condition so that we can
% generate artificial data for each one. This is to simulate data that you
% might obtain in an experiment with three conditions.

%% Generate data
% Let's suppose our subject completed 3 different conditions.
condition1model = taskmodel;
condition2model = taskmodel;
condition3model = taskmodel;

% Now let's suppose that these conditions are associated with differences
% in this subject's data. To do this, let's enter different parameter values 
% for each condition.
condition1model.ampvals = [1 5 7 2];
condition1model.latvals = [-50 -180 60 0];
condition1model.boxampvals = [3];
condition1model.tmaxval = 930;

condition2model.ampvals = [7 2 9 4];
condition2model.latvals = [120 -20 -110 90];
condition2model.boxampvals = [1];
condition2model.tmaxval = 1200;

condition3model.ampvals = [8 3 4 5];
condition3model.latvals = [-190 -250 -20 -110];
condition3model.boxampvals = [6];
condition3model.tmaxval = 800;

% Now let's generate the data. Let's make 200 trials for each condition and
% set the parameter generation mode to 'normal' (this means the parameters
% used to generate each trial will be normally distributed around the
% values we defined above).
numtrials = 200;
parammode = 'normal';

condition1data = pret_fake_data(numtrials,parammode,taskmodel.samplerate,taskmodel.window,condition1model);
condition2data = pret_fake_data(numtrials,parammode,taskmodel.samplerate,taskmodel.window,condition2model);
condition3data = pret_fake_data(numtrials,parammode,taskmodel.samplerate,taskmodel.window,condition3model);

%% visualize generated data
sfact = taskmodel.samplerate/1000;
time = taskmodel.window(1):1/sfact:taskmodel.window(2);

close all

figure(1)
plot(time,condition1data)
title('Condition 1')
xlabel('time (ms)')
ylabel('pupil size (% change from baseline')

figure(2)
plot(time,condition2data)
title('Condition 2')
xlabel('time (ms)')
ylabel('pupil size (% change from baseline')

figure(3)
plot(time,condition3data)
title('Condition 3')
xlabel('time (ms)')
ylabel('pupil size (proportion change from baseline')

%% organize data via pret_preprocess
% To fit pupil data you collected in an experiment, you would start here,
% with preprocessing. The data should be epoched by trial in a matrix of
% trials x time for each condition. pret_preprocess creates an sj
% (subject) structure with the data and metadata in a set format. If
% requested, it also performs baseline normalization and blink 
% interpolation on the trial data.

% The artificial data is already baseline normalized and has no blinks, so 
% we return the options structure and turn off those features
options = pret_preprocess();
options.normflag = false;
options.blinkflag = false;

% put the condition data matrices into a cell array
data = {condition1data condition2data condition3data};

% labels for each condition
condlabels = {'condition1' 'condition2' 'condition3'};

% other epoch info
samplerate = taskmodel.samplerate;
window = taskmodel.window;

sj = pret_preprocess(data,samplerate,window,condlabels,[],options);

%% create model for the data
% Pretending that we are naive to the model that we used to create our
% data, let's create a model to actually fit the data to.
model = pret_model();

% While the trial window of our task is from -500 to 3500 ms, here we are
% not interested in what's happening before 0. So
% let's set the model window to fit only to the region betweeen 0 and 3500
% ms (the cost function will only be evaluated along this interval).
model.window = [0 3500];

% We already know the sampling frequency.
model.samplerate = taskmodel.samplerate;

% We also know the event times of our task. Let's also say that we think 
% there will be a sustained internal signal from precue onset to response 
% time (0 to 2750 ms).
model.eventtimes = [0 1000 1250 1750];
model.eventlabels = {'precue' 'stim1' 'stim2' 'postcue'}; %optional
model.boxtimes = {[0 2750]};
model.boxlabels = {'task'}; %optional

% Let's say we want to fit a model with the following parameters: 
% event-related, amplitude, latency, task-related (box) amplitude, 
% and the tmax of the pupil response function. We turn the other parameters
% off.
model.yintflag = false;
model.slopeflag = false;

% Now let's define the bounds for the parameters we decided to fit. We do
% not have to give values for the y-intercept and slope because we are not
% fitting them.
model.ampbounds = repmat([0;100],1,length(model.eventtimes));
model.latbounds = repmat([-500;500],1,length(model.eventtimes));
model.boxampbounds = [0;100];
model.tmaxbounds = [500;1500];

% We need to fill in the values for the y-intercept and slope since we will
% not be fitting them as parameters.
model.yintval = 0;
model.slopeval = 0;

%% estimate model parameters via pret_estimate_sj
% Now let's perform the parameter estimation procedure on our subject data.
% The mean of each condition will be fit independently. For illustration, 
% let's run only 3 optimizations using one cpu worker (for more 
% information, see the help files of pret_estimate and pret_estimate_sj).
options = pret_estimate_sj();
options.pret_estimate.optimnum = 3;
% if you want to try fiting the parameters using single trials instead of the mean,
% use these lines (you'll want to turn off the optimization plots for this):
%   options.trialmode = 'single';
%   options.pret_estimate.pret_optim.optimplotflag = false;
wnum = 1;

sj = pret_estimate_sj(sj,model,wnum,options);

%% Compare model fits to condition means
close all

figure(1)
gobj1 = plot(time,sj.means.condition1,'k','LineWidth',1.5);
hold on
[~, gobj2] = pret_plot_model(sj.estim.condition1);
legend([gobj1 gobj2],{'data' 'model'});

figure(2)
gobj1 = plot(time,sj.means.condition2,'k','LineWidth',1.5);
hold on
[~, gobj2] = pret_plot_model(sj.estim.condition2);
legend([gobj1 gobj2],{'data' 'model'});

figure(3)
gobj1 = plot(time,sj.means.condition3,'k','LineWidth',1.5);
hold on
[~, gobj2] = pret_plot_model(sj.estim.condition3);
legend([gobj1 gobj2],{'data' 'model'});

%% perform bootstrapping procedure via pret_bootstrap_sj
% Finally, let's perform the bootstrapping procedure on our subject data.
% Each condition will be bootstrapped independently. Let's lower the number
% of bootstrap iterations and the number of optimizations (in the
% estimation procedure performed during each bootstrap iteration). For more
% information, see the help files of pret_bootstrap and pret_bootstrap_sj.
% 
% summary figures showing distribution of each parameter's bootstrap
% estimations will appear automatically
options = pret_bootstrap_sj();
options.pret_bootstrap.pret_estimate.optimnum = 3;
wnum = 1;
nboots = 5;

sj = pret_bootstrap_sj(sj,model,nboots,wnum,options);

%% condition 1 bootstrap results
% These box and whisker plots show the median, quartiles, and 95%
% confidence interval of each parameter (we only completed 5 bootstrap
% iterations, so these plots only represent distributions of 5 points).
close all
pret_plot_boots(sj.boots.condition1,model);

%% condition 2 bootstrap results
close all
pret_plot_boots(sj.boots.condition2,model);

%% condition 3 bootstrap results
close all
pret_plot_boots(sj.boots.condition3,model);

%% Single trial estimation with variable event timing
% In some experiments, event timing varies from trial to trial. In that
% case, we can't use a fixed set of eventtimes and boxtimes but need to
% model separate timings for each trial. We also need to simultaneously fit
% all the single trial timeseries, rather than fitting the mean.
%
% Let's modify condition1 from above to simulate this situation. Here let's
% say that stim1 occurs at a different time every trial, varying between
% 500 and 1000 ms. Here we specify the event times for each trial
condition4model = condition1model;
condition4model.eventtimes = repmat([0 1000 1250 1750],numtrials,1);
stim1times = round(rand(numtrials,1)*500 + 500);
condition4model.eventtimes(:,2) = stim1times;

% Even though the box times are the same for all trials, boxtimes must also
% now have a row for each trial
condition4model.boxtimes{1} = repmat([0 2750],numtrials,1);

% Generate fake data for condition4, trial by trial
condition4data = [];
for itr = 1:numtrials
    mtr = condition4model; % model for this trial
    mtr.eventtimes = condition4model.eventtimes(itr,:);
    mtr.boxtimes{1} = condition4model.boxtimes{1}(itr,:);
    condition4data(itr,:) = pret_fake_data(1,parammode,...
        taskmodel.samplerate,taskmodel.window,mtr);
end

% Make a new subject structure. We could use pret_preprocess for this; in
% this example, we set it up by hand
sj1 = [];
sj1.samplerate = 1000;
sj1.trialwindow = [-500 3500];
sj1.conditions = {'condition4'};
sj1.condition4 = condition4data;

% Adapt the model to include the single trial event times
model1 = model;
model1.eventtimes = condition4model.eventtimes;
model1.boxtimes = condition4model.boxtimes;

% Initialize pret_estimate_sj options and set trialmode to "single" to fit
% single trial data
options1 = pret_estimate_sj();
options1.trialmode = 'single';

% For demo purposes, these numbers are small
options1.pret_estimate.searchnum = 20;
options1.pret_estimate.optimnum = 1;

% Fit the model
sj1 = pret_estimate_sj(sj1,model1,wnum,options1);

