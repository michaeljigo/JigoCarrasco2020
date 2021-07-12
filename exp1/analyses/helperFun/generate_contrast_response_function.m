% Purpose:  Generate contrast response function (CRF) based on thresholds estimated from functional form of contrast sensitivity function (CSF) and a profile of attentional modulation.

function [model crf] = generate_contrast_response_function(data,crf,thresholds)

%% Generate psychometric functions
% repeat CRF parameters into the full parameter matrix
crfParams = {'slope' 'upperAsymptote'};
for p = 1:numel(crfParams)
   if ~isequal(size(crf.(crfParams{p})),crf.fullMatrixSize)
      currentDim = size(crf.(crfParams{p}));
      shift = numel(crf.fullMatrixSize)-sum(currentDim>1);
      
      % determine which dimensions need to be repeated
      repeatSize = crf.fullMatrixSize(~ismember(crf.fullMatrixSize,currentDim(currentDim>1)));
       
      % shift and repeat matrix
      crf.(crfParams{p}) = shiftdim(crf.(crfParams{p}),-shift);
      crf.(crfParams{p}) = squeeze(repmat(crf.(crfParams{p}),[repeatSize 1]));

      % rearrange repeated matrix to match full matrix
      [~,correctOrder] = ismember(crf.fullMatrixSize,size(crf.(crfParams{p})));
      crf.(crfParams{p}) = permute(crf.(crfParams{p}),correctOrder);
   end
end

% evaluate CRFs for each condition
for e = 1:numel(data.eccVal)
   for s = 1:numel(data.sfVal)
      for c = 1:data.nCue
         % put together crf parameters
         switch crf.name
            case 'logistic'
               % thresholds from CSF model reflect 75% accuracy, adjust them so that they correspond to midpoint between upper and lower asymptote
               thresholdEstimate = log10(thresholds(e,s,c));
               %thresholdEstimate = thresholdEstimate+log((1-0.5-crf.upperAsymptote(e,s,c))./(0.75-0.5)-1)./crf.slope(e,s,c);
               %if ~isreal(thresholdEstimate)
                  %thresholdEstimate = 0;
               %end

               params = [thresholdEstimate crf.slope(e,s,c) 0.5 crf.upperAsymptote(e,s,c)];
            case 'nakarushton'
               params = [thresholds(e,s,c) crf.slope(e,s,c) 0 crf.upperAsymptote(e,s,c)];
         end
         % get probabilities from CRF model 
         model{s,e}(c,:) = evalPF(crf.name,data.contrasts{s,e},params);
      end
   end
end
