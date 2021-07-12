% Purpose:  Generate the Neutral contrast thresholds estimated from the parameters of a functional form of the contrast sensitivity function (CSF) that vary with eccentricity.
%           Parameters will be constrained to vary with eccentricity with an intercept and slpe.

function thresholds = generate_neutral_thresholds(data,csf,crf)

%% Compute parameter values for tested eccentricities
switch csf.name
   case 'logparab'
      cs_max = 10.^(csf.cs_int+csf.cs_slope*data.eccVal);
      freq_max = 2.^(csf.freq_int+csf.freq_slope*data.eccVal);
      bw = csf.bw_int+csf.bw_slope*data.eccVal;
end

%% Generate contrast thresholds for tested spatial frequencies
sfs = data.sfVal;
for e = 1:numel(data.eccVal)
   switch csf.name
      case 'logparab'
         neutralThresh(e,:) = evalCSF(csf.name,sfs,[freq_max(e) bw(e) cs_max(e)]);
   end
end
% convert from contrast sensitivity to thresholds
neutralThresh(neutralThresh<1) = 1;
thresholds = 1./neutralThresh;

% re-arrange matrix to match order of CRF parameters
[~,correctOrder] = ismember(crf.fullMatrixSize,size(thresholds));
thresholds = permute(thresholds,correctOrder);
