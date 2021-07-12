% Purpose:  Extract thresholds from the fitted full model. 
%           Two thresholds will be extracted: one corresponding to the contrast needed to attain 75% accuracy (thresh75), another to the midpoint between lower and upper asymptotes (threshMid). 

function [thresh75 threshMid crf attn] = extract_thresholds(data,csf,attn,crf)

%% Get thresholds from the best-fitting CSF function
[thresh75, ~, attn] = generate_neutral_valid_thresholds(data,csf,attn,crf);


%% Adjust thresholds to reflect mid-point between upper and lower asymptotes
% get crf in the full-matrix form (i.e., with all parameters for all conditions)
[~,crf] = generate_contrast_response_function(data,crf,thresh75);

switch crf.name
   case 'logistic'
      threshMid = log10(thresh75);
      %threshMid = real(threshMid+log((1-0.5-crf.upperAsymptote)./(0.75-0.5)-1)./crf.slope);
      thresh75 = log10(thresh75);
   otherwise
      threshMid = thresh75;
end
