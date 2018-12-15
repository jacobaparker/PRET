% pret_sample_script
% 
% A script demonstrating a sample workflow with PRET using a sample dataset
% and model. Can also be used to quickly test if PRET is working (will test
% most things).

%% load sample data
% 
% data1 = 200 pupil size time series that are individual trials for a
% single condition.
% 
% model1 = a model structure created by pret_model and already filled out.
% data1 was generated by using pret_fake_data with this model
% 
% samplerate = the sampling frequency of data1 in Hz.
% 
% trialwindow = the starting and ending times (in ms) of the trial epoch
% for data1.
% 
% condlabels = the condition label for data1.

load pret_sample_data.mat

%% visualize sample data
sfact = samplerate/1000;
time = trialwindow(1):1/sfact:trialwindow(2);

figure
plot(time,data1)
xlabel('time (ms)')
ylabel('pupil size (proportion change from baseline')

%% organize via pret_preprocess
% data is already baseline normalized and has no blinks, so we need to
% return options structure and turn off those features
options = pret_preprocess();
options.normflag = false;
options.blinkflag = false;

sj = pret_preprocess({data1},samplerate,trialwindow,condlabels,[],options);

%% estimate model parameters via pret_estimate_sj
% lower number of optimizations completed for sake of demonstration
options = pret_estimate_sj();
options.pret_estimate.optimnum = 3;

sj = pret_estimate_sj(sj,model1,options);

%% view best model fit via pret_plot_model and compare to mean of data1
plot(time,sj.means.data1,'k','LineWidth',1.5)
hold on
pret_plot_model(sj.estim.data1);

%% perform bootstrapping procedure via pret_bootstrap_sj
% lower of optimizations per estimation for demonstration purposes
% only use 1 cpu
% summary figures showing distribution of each parameter's bootstrap
% estimations will appear automatically
options = pret_bootstrap_sj();
options.pret_bootstrap.pret_estimate.optimnum = 3;
wnum = 1;

sj = pret_bootstrap_sj(sj,model1,5,wnum,options);