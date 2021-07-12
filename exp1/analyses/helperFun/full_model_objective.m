% Purpose:  Fit full model (i.e., CSF, Attention modulation, and CRF) to dataset given inputted constraints on parameter values.

function cost = full_model_objective(data,csf,attn,crf,params)

%% Re-structure parameters
[~,~,csf,attn,crf] = vectorize_parameters(csf,attn,crf,params);


%% Generate thresholds
thresholds = generate_neutral_valid_thresholds(data,csf,attn,crf);


%% Generate modeled performance across contrast levels
model = generate_contrast_response_function(data,crf,thresholds);


%% Compute error metric
switch crf.name
   case 'logistic'
      % collapse across conditions 
      model = cellfun(@(x) x(:),model,'UniformOutput',0); model = cell2mat(model(:))';
      ncorr = cellfun(@(x) x(:),data.ncorr,'UniformOutput',0); ncorr = cell2mat(ncorr(:))';
      ntrials = cellfun(@(x) x(:),data.ntrials,'UniformOutput',0); ntrials = cell2mat(ntrials(:))';

      % compute negative log-likelihood of entire dataset
      cost = -computeLL(model,ncorr,ntrials);
   case 'nakarushton'
      model = cellfun(@(x) x(:),model,'UniformOutput',0); model = cell2mat(model(:))';
      performance = cellfun(@(x) x(:),data.performance,'UniformOutput',0); performance = cell2mat(performance(:))';
      ntrials = cellfun(@(x) x(:),data.ntrials,'UniformOutput',0); ntrials = cell2mat(ntrials(:))';

      %performance(performance<0) = nan;
      
      % copmute weighted sum of squares
      cost = nansum(ntrials.*((model-performance).^2))./nansum(ntrials);
      %cost = nansum(ntrials.*((model-performance).^2));
end
