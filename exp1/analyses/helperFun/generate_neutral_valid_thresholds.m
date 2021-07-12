% Purpose:  Generate the Neutral contrast thresholds estimated from the parameters of a functional form of the contrast sensitivity function (CSF). 
%           Then, generate the Valid thresholds by modulating the CSF by an attentional form.

function [thresholds attnModulation attn] = generate_neutral_valid_thresholds(data,csf,attn,crf)

%% Generate Neutral contrast thresholds
for e = 1:numel(data.eccVal)
   switch csf.name
      case 'dexp'
         paramOrder = {'slope' 'peakSF' 'amplitude'};
         params = nan(1,numel(paramOrder));
         for order = 1:numel(paramOrder)
            params(order) = csf.(paramOrder{order})(e);
         end
         sfs = data.sfVal;
      case 'asymGaus'
         paramOrder = {'peakSF' 'lowSlope' 'highSlope' 'exponent' 'peakCS' 'baseline'};
         params = nan(1,numel(paramOrder));
         for order = 1:numel(paramOrder)
            if ismember(paramOrder{order},fieldnames(csf))
               params(order) = csf.(paramOrder{order})(e);
            elseif strcmp(paramOrder{order},'exponent')
               params(order) = 2;
            elseif strcmp(paramOrder{order},'baseline')
               params(order) = 1;
            end
         end
         sfs = log2(data.sfVal);
      case 'logparab'
         paramOrder = {'peakSF' 'bandwidth' 'amplitude'};
         params = nan(1,numel(paramOrder));
         for order = 1:numel(paramOrder)
            params(order) = csf.(paramOrder{order})(e);
         end
         sfs = data.sfVal;
   end

   % evalute contrast sensitivity functional form
   neutralThresh(e,:) = evalCSF(csf.name,sfs,params);
end


%% Generate Valid contrast thresholds
% if any parameters are to be fixed across eccentricity, only one parameter value will be inputted. 
% repeat this value to match the # of eccentricities
fields = fieldnames(attn); fields = fields(~ismember(fields,{'bnd' 'name'}));
for order = 1:numel(fields)
   if numel(attn.(fields{order}))==1
      attn.(fields{order}) = repmat(attn.(fields{order}),1,numel(data.eccVal));
   end
end

% evaluate form of attention modulation 
if numel(fields)==1
   % multiplicative scaling
   attnModulation = repmat(attn.amplitude',1,numel(data.sfVal));
else
   % asymmetric Gaussian functions
   paramOrder = {'center' 'lowSlope' 'highSlope' 'exponent' 'amplitude' 'baseline'};
   for e = 1:numel(data.eccVal)
      params = nan(1,numel(paramOrder));
      for order = 1:numel(paramOrder)
         if ismember(paramOrder{order},fieldnames(attn))
            params(order) = attn.(paramOrder{order})(e);
         elseif strcmp(paramOrder{order},'highSlope')
            params(order) = attn.lowSlope(e);
         elseif strcmp(paramOrder{order},'baseline')
            params(order) = 1;
         end
      end
      % attentional modulation will reflect percent change in contrast sensitivity
      attnModulation(e,:) = asymGaussian(log2(data.sfVal),params);
   end
end

% modulate neutral contrast sensitivity
validThresh = neutralThresh.*attnModulation;

% convert from contrast sensitivity to thresholds
thresholds(1,:,:) = 1./neutralThresh;
thresholds(2,:,:) = 1./validThresh;

% re-arrange matrix to match order of CRF parameters
[~,correctOrder] = ismember(crf.fullMatrixSize,size(thresholds));
thresholds = permute(thresholds,correctOrder);

% constrain thresholds to have a maximum of 1
thresholds(thresholds>1) = 1;
