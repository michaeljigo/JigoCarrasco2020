% Purpose:  Pack up the data for Experiment 2 results in Jigo & Carrasco, 2020.
%           This function will create an easy-to-handle structure where analysis results are held.
%
% By:       Michael Jigo
%           05.26.21

function [data params] = pack_experiment_results
addpath(genpath('./helperFun'));

%% Initialize parameters
params.use_dprime    = 1;                       % performance quantified with d-prime
params.csfShape      = 'dexp';                  % functional form of the contrast sensitivity function 
params.attnModelNum  = 1;                       % attention model parameters are free to vary among eccentricities
params.attntype      = {'exo' 'endo'};          % attention types to process
params.attnShape     = {'symmetric' 'uniform'}; % SF profiles
params.subjList      = {'AS' 'DT' 'KT' 'MJ' 'MM' 'RF' 'SO' 'SP' 'SX' 'YS'};


%% Loop through attention types and load respective datasets
for a = 1:numel(params.attntype)
   % load each subject's data
   for s = 1:numel(params.subjList)

      % load attention parameters
      dataDir = sprintf('../%s/data/%s/fullModel/',params.attntype{a},params.subjList{s});
      load(sprintf('%sfitParameters_%s%i_dprime.mat',dataDir,params.attnShape{a},params.attnModelNum));
   

      % Experiment parameters
         % eccentricities
         newdata(a).ecc = data.eccVal;

         % SFs
         newdata(a).freq = data.sfVal;

         % grating size
         newdata(a).grating_diameter = 4; % 4 deg wide gratings

      
      % Performance
         newdata(a).performance(s,:,:,:) = data.performance; % [cue freq ecc]
         newdata(a).attn_effect(s,:,:) = generate_valid_benefit(data,attn)';

      
      % Attention parameters
         % center SF
         newdata(a).attn.centerSF(s,:) = attn.center;

         % bandwidth
         newdata(a).attn.bandwidth(s,:) = attn.lowSlope;

         % amplitude
         newdata(a).attn.amplitude(s,:) = attn.amplitude;

         % exponent
         newdata(a).attn.exponent(s,:) = attn.exponent;


      % CSF parameters
         % load CSF parameters
         dataDir = sprintf('../%s/data/%s/',params.attntype{a},params.subjList{s});
         load(sprintf('%scsf_%s.mat',dataDir,params.csfShape));
         
         % peak SF
         csf.peakSF     = csfParams(:,2);
         csf.amplitude  = csfParams(:,3);
         csf.slope      = csfParams(:,1);
         newdata(a).csf.peakSF(s,:) = csf.peakSF;

         % max CS
         tmp = csf.amplitude.*csf.peakSF.^(csf.peakSF./csf.slope).*exp(-csf.peakSF./csf.slope);
         newdata(a).csf.maxCS(s,:) = tmp; % actual peak contrast sensitivity
         newdata(a).csf.amplitude(s,:) = csf.amplitude; % model parameter of amplitude

         % shape parameter
         newdata(a).csf.shape(s,:) = csf.slope;


      % Thresholds
         % store Neutral thresholds
         newdata(a).thresh(s,:,:) = avgCSF(1:numel(newdata(a).freq),:);
   end
end
data = newdata;
