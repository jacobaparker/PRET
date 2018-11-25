# PRET #
__Pupil Response Estimation Toolbox (PRET)__

  by Jacob Parker and Rachel Denison
  
  Welcome to the Pupil Response Estimation Toolbox (PRET)! This is a freely available, Matlab toolbox for analyzing pupillometry
  data by modeling the pupil size time series as a linear combination of pupil responses to discrete events occurring over time.
  The functions in this toolbox can be used to implement the analysis described in (insert paper here)[1], which builds upon the
  paradigm created by Hoeks and Levelt in 1993[2]. Once you download PRET, you will be _ready_ to complete this type of analysis         yourself.
  
## Overview ##
  PRET works with data that has already been epoched and organized into separate trials.

  With this toolbox, you can:
  * Perform simple preprocessing (baseline normalization and blink interpolation)
  * Create models of pupil dilation for a particular task
  * Estimate model parameters for a given dataset and model
  * Bootstrap a dataset and estimate model parameters on each iteration
  * Plot the results of model estimation and the bootstrapping procedure
  * Perform estimation and/or bootstrapping procedure with multiple models for one or more datasets
  
## Functions ##
Function | Description
---------|------------
blinkinterp.m | performs blink interpolation as described in Mathôt 2013[3]
pret_bootstrap.m | performs the bootstrapping procedure on one set of trials with one model
pret_bootstrap_sj.m | performs the bootstrapping procedure on data in an "sj" structure with one or more models
pret_calc.m | calculates the individual pupil reponse regressors and the predicted time series
pret_cost.m | calculates the sum of the square errors between data and a model produced time series
pret_default_options.m | establishes the default options for all PRET functions
pret_estimate.m | estimates model parameters for a single pupil time series
pret_estimate_sj.m | performs parameter estimation on data in an "sj" structure with one or more models
pret_fake_data.m | produces artificial data by using randomly generated parameters for a specific model
pret_generate_params.m | generates random parameters for a specific model
pret_model.m | creates an empty "model" structure containing model specifications
pret_model_check.m | checks if input "model" structure makes sense
pret_optim.m | performs constrained optimization to fit model parameters to a single pupil size time series
pret_plot_boots.m | plots the results of performing the bootstrapping procedure
pret_plot_model.m | plots a model or the results of the estimation procedure
pret_preprocess.m | performs simple preprocessing of data and/or organizes it into an "sj" structure
pupilrf.m | creates a pupil response function with the input parameters[2]

## Workflow ##
Starting with data that has already been epoched and organized into separate trials, the workflow looks like this:
1. Preprocess and/or organize data into "sj" structure with pret_preprocess.m
2. Build models to test by creating "model" structures with pret_model.m and filling them out
3. Estimate parameters for each model on data in "sj" structure with pret_estimate_sj.m
4. Perform bootstrapping procedure on data in "sj" for the best model or all models using pret_bootstrap_sj.m
If you have multiple subjects (datasets), you can create multiple "sj" structures and use pret_batch_process.m to perform
the estimation and bootstrapping procedures for multiple models in one run.

## Considerations ##
* The estimation procedure may take a signficant amount of time, depending on the number of datasets being fit
* The bootstrap procedure may only be feasible with a multicore machine, depending on the number of bootstrap iterations desired and the number of datasets being fit

## References ##
  1. (insert paper here)
  2. "Pupillary dilation as a measure of attention: A quantitative system analysis", Hoeks and Levelt 1993
  3. "A simple way to reconstruct pupil size during eye blinks", Mathôt 2013
