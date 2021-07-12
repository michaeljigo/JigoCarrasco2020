% Purpose:  Pack up the data for Experiment 1 results in Jigo & Carrasco, 2020.
%           This function will create an easy-to-handle structure where analysis results are held.
%
% By:       Michael Jigo
%           05.25.21

function [data params] = pack_experiment_results
addpath('./helperFun');

%% Initialize parameters
params.use_dprime    = 1;                       % performance quantified with d-prime
params.csfShape      = 'dexp';                  % functional form of the contrast sensitivity function 
params.crfShape      = 'nakarushton';           % functional form of the contrast response function
params.crfModelNum   = 5;                       % CRF slope is fixed across SF and cueing conditions
params.attnModelNum  = 1;                       % attention model parameters are free to vary among eccentricities
params.attntype      = {'exo' 'endo'};          % attention types to process
params.attnShape     = {'symmetric' 'uniform'}; % SF profiles
params.subjList      = {'AB' 'AF' 'AS' 'LH' 'LS' 'MJ' 'RF' 'SC' 'SX'};


%% Loop through attention types and load respective datasets
for a = 1:numel(params.attntype)
   %% load each subject's data
   for s = 1:numel(params.subjList)
      dataDir = sprintf('../%s/data/%s/fullModel/',params.attntype{a},params.subjList{s});
      load(sprintf('%sfitParameters_%s_%s%i_%s%i_dprime.mat',dataDir,params.csfShape,params.crfShape,params.crfModelNum,params.attnShape{a},params.attnModelNum));
   

      %% Experiment parameters
         % eccentricities
         newdata(a).ecc = data.eccVal;

         % SFs
         newdata(a).freq = data.sfVal;

         % grating size
         newdata(a).grating_diameter = 4; % 4 deg wide gratings


      %% CRF parameters
         % thresholds (i.e., contrast level needed for 75% accuracy)
         [newdata(a).crf.thresh(s,:,:,:),~,~] = generate_neutral_valid_thresholds(data,csf,attn,crf);

         % upper asymptote
         newdata(a).crf.rmax(s,:,:,:) = crf.upperAsymptote;

         % slope
         newdata(a).crf.slope(s,:,:,:) = crf.slope;

      
      %% CSF parameters
         % peak SF
         newdata(a).csf.peakSF(s,:) = csf.peakSF;

         % max CS
         tmp = csf.amplitude.*csf.peakSF.^(csf.peakSF./csf.slope).*exp(-csf.peakSF./csf.slope);
         newdata(a).csf.maxCS(s,:) = tmp;

         % shape parameter
         newdata(a).csf.shape(s,:) = csf.slope;


      %% Attention parameters
         % center SF
         newdata(a).attn.centerSF(s,:) = attn.center;

         % bandwidth
         newdata(a).attn.bandwidth(s,:) = attn.lowSlope;

         % amplitude
         newdata(a).attn.amplitude(s,:) = attn.amplitude;

         % exponent
         newdata(a).attn.exponent(s,:) = attn.exponent;
   
         % attention modulation function
         [~,newdata(a).attn.attn_mod(s,:,:),~] = generate_neutral_valid_thresholds(data,csf,attn,crf);
   end
      % Get average attention modulation
         attnCenter = log(mean(exp(newdata(a).attn.centerSF)));
         attnSlope = mean(newdata(a).attn.bandwidth);
         attnAmp = mean(newdata(a).attn.amplitude);
         attnExp = mean(newdata(a).attn.exponent);
         attn.center = attnCenter;
         attn.lowSlope = attnSlope;
         attn.amplitude = attnAmp;
         attn.exponent = attnExp;
         [~,newdata(a).attn.avg_modulation,~] = generate_neutral_valid_thresholds(data,csf,attn,crf);
      
      % keep variation of thresholds
         newdata(a).crf.raw_thresh = newdata(a).crf.thresh;


      % adjust thresholds by the average attention modulation function 
         if strcmp(params.attntype{a},'exo')
            attnmod = repmat(shiftdim(newdata(a).attn.avg_modulation,-1),[size(newdata(a).crf.thresh,1) 1 1]);
            newdata(a).crf.thresh(:,:,:,2) = newdata(a).crf.thresh(:,:,:,1)./attnmod;
         else
            newdata(a).crf.thresh(:,:,:,2) = newdata(a).crf.thresh(:,:,:,1)./newdata(a).attn.attn_mod;
            newdata(a).attn.avg_modulation = squeeze(mean(newdata(a).attn.attn_mod,1));
         end


      % generate bootstrap samples for thresholds
      [~,newdata(a).crf.thresh_boot] = get_bootstrap_ci(log(newdata(a).crf.thresh));
      newdata(a).crf.thresh_boot = exp(newdata(a).crf.thresh_boot);

      % load and store group average fit
      %filename = sprintf('../%s/data/group/group_average_fit.mat',params.attntype{a});
      %load(filename);
      %newdata(a).groupavgFit = groupavgFit;
end
data = newdata;
