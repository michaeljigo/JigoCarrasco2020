% Purpose:  Fit full model (i.e., Neutral and Attention) to dataset given inputted constraints on parameter values.

function cost = full_model_objective(data,attn,params)

%% Re-structure parameters
[~,~,attn] = vectorize_parameters(attn,params);

%% Generate attention effect
model = generate_valid_benefit(data,attn)';

%% Compute error metric
data_cueEffect = squeeze(diff(data.performance,[],1));

% compute sum of squared error
cost = nansum((data_cueEffect(:)-model(:)).^2);
