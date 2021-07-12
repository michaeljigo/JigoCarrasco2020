% Purpose:  Generate the increase in performance due to valid cues, based on parameters of symmetric, skewed, or uniform Gaussian modulations.

function attnIncrease = generate_valid_benefit(data,attn);

%% Generate change in performance during Valid condition
% if any parameters are to be fixed across eccentricity, only one parameter value will be inputted. 
% repeat this value to match the # of eccentricities
fields = fieldnames(attn); fields = fields(~ismember(fields,{'bnd' 'name'}));
for order = 1:numel(fields)
   if numel(attn.(fields{order}))==1
      attn.(fields{order}) = repmat(attn.(fields{order}),1,numel(data.eccVal));
   end
end

% evaluate form of attention modulation 
paramOrder = {'center' 'lowSlope' 'highSlope' 'exponent' 'amplitude' 'baseline'};
for e = 1:numel(data.eccVal)
   params = nan(1,numel(paramOrder));
   for order = 1:numel(paramOrder)
      if ismember(paramOrder{order},fieldnames(attn))
         params(order) = attn.(paramOrder{order})(e);
      elseif strcmp(paramOrder{order},'highSlope')
         params(order) = attn.lowSlope(e);
      elseif strcmp(paramOrder{order},'baseline')
         params(order) = 0;
      end
   end
   % attentional modulation will increase in performance from baseline
   attnIncrease(e,:) = asymGaussian(log2(data.sfVal),params);
end
