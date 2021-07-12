% Purpose:  Fit hypothesis to cueing effects and extract parameters of the center, spread, and 
%           amplitude.

function [params cost] = fitHypothesis(data,currentAttn,hyp)

%% Align SF or not
%if hyp.aligned
   %octaves(:,:) = octavesFromPeak(squeeze(thresh(hyp.currentSample,:,:,:)),data.opt.sfVal);
%end

%% Perform fit to data
% initial parameters for optimization
init = repmat(rand(1,6),numel(data.eccVal),1);

% repeat bounds to account for all eccentricities
lb = repmat(hyp.paramRange(1,:),size(init,1),1);
ub = repmat(hyp.paramRange(2,:),size(init,1),1);

% get fixed parameter structure
fixedParams = hyp.fixOrFree.(['model',num2str(hyp.eccModel)]);

% set up solver
ms = MultiStart('XTolerance',1e-6,'Display','none','StartPointsToRun','bounds','UseParallel',0);
fitFun = @(params)fit_asymGauss(data,currentAttn,params,fixedParams);
modelProb = createOptimProblem('fmincon','objective',fitFun,'x0',init(:),'lb',lb(:),'ub',ub(:),'options',hyp.options);
[params cost] = run(ms,modelProb,hyp.nStartPoints);

% reformat parameters to a cue x eccentricity x parameter matrix
params = reshape(params,numel(data.eccVal),numel(fixedParams));
         

%% Objective function
function [cost,model] = fit_asymGauss(data,attn,p,fixedParams)
% parameters for the asymmetric gaussian are
% p(1) = mu (center)
% p(2) = sigma left (spread to the left of center)
% p(3) = sigma right (spread to the right of center)
% p(4) = exponent (shape)
% p(5) = amplitude

% reshape parameters to have e x 6 matrix
p = reshape(p,numel(data.eccVal),numel(fixedParams));

% if fixing any parameters, do fixing now
for e = 1:size(p,1)
   for f = 1:numel(fixedParams)
      if isnan(fixedParams{f})
         continue
      else
         if ischar(fixedParams{f})
            p(e,f) = eval(fixedParams{f});
         else
            p(e,f) = fixedParams{f};
         end
      end
   end
end

% evaluate model
for e = 1:numel(data.eccVal)
   model(e,:) = asymGaussian(log2(data.sfVal),p(e,:));
end

% rmse
%cost = sqrt(mean((model(:)-attn(:)).^2));
% sse
cost = nansum((model(:)-attn(:)).^2);
