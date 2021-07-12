% Purpose:  This function will initialize the hypotheses (symmetric, skewed, uniform) for fitting purposes.
%           That is, it will initialize a structure that contains the bounds, and constraints of 
%           eccentricity-dependent models.
%
% Input:
% hypName   -  'symmetric' or 'skewed' or 'uniform'
%
% Optional input:
% muBnd     -  vector defining bounds of mu parameter
% sprdBnd   -  vector defining bounds of spread parameters
% expnBnd   -  vector defining bounds of exponent
% ampBnd    -  vector defining bounds of amplitude
% aligned   -  0=no alignment to peakSF; 1=align to peakSF

function hyp = initHypothesis(hypName,hypEccModel,varargin)

%% Parse optional inputs
optionalIn = {'muBnd' 'sprdBnd' 'expnBnd' 'ampBnd' 'baseBnd' 'aligned' 'nStartPoints'};
optionalVal = {[log2(0.7071) log2(8)] [0.5 2.5] [10 10] [0 2] [1 1] 0 2};
opt = parseOptionalInputs(optionalIn,optionalVal,varargin);


%% Fitting options
options = optimoptions(@fmincon,'Algorithm','interior-point','Display','none','MaxIter',1e4,...
   'FunctionTolerance',1e-3,'StepTolerance',1e-10,'MaxFunctionEvaluations',1e50);


%% Choose the hypothesis that will be evaluated
% set constraints on parameters
paramRange = [opt.muBnd' opt.sprdBnd' opt.sprdBnd' opt.expnBnd' opt.ampBnd' opt.baseBnd'];

% set hypothesis-specific constraints
symmetricSpread = 0; % both spread parameters (left and right) are independent by default
switch hypName
   case {'symmetric'}
      % exponent can only equal 2
      paramRange(:,4) = 2;

      % identical spread parameters
      symmetricSpread = 1;
   case {'skewed'}
      % exponent can only equal 2
      paramRange(:,4) = 2;
   case {'uniform'}
      % exponent can only be larger than 3
      paramRange(1,4) = 5;

      % identical spread parameters
      symmetricSpread = 1;
   otherwise
      error('hypName must be symmetric, skewed, or uniform.');
end


%% Setup all 8 eccentricity-dependent models
% Note: all models have the exponent fixed across eccentricities.
% Note2: model order below follows that in manuscript. The original order was [1 3 5 4 7 6 8 2]
if ~symmetricSpread
   % the hypothesis does not demand symmetric spreads, so "left" and "right" spreads are independent
   fixOrFree.model1 = {'p(e,1)' 'p(e,2)' 'p(e,3)' 'p(1,4)' 'p(e,5)' 1}; % all free
   fixOrFree.model2 = {'p(1,1)' 'p(e,2)' 'p(e,3)' 'p(1,4)' 'p(e,5)' 1}; % mu fixed
   fixOrFree.model3 = {'p(e,1)' 'p(e,2)' 'p(e,3)' 'p(1,4)' 'p(1,5)' 1}; % amplitude fixed
   fixOrFree.model4 = {'p(e,1)' 'p(1,2)' 'p(1,3)' 'p(1,4)' 'p(e,5)' 1}; % spread fixed
   fixOrFree.model5 = {'p(1,1)' 'p(e,2)' 'p(e,3)' 'p(1,4)' 'p(1,5)' 1}; % mu + amplitude fixed
   fixOrFree.model6 = {'p(1,1)' 'p(1,2)' 'p(1,3)' 'p(1,4)' 'p(e,5)' 1}; % mu + spread fixed
   fixOrFree.model7 = {'p(e,1)' 'p(1,2)' 'p(1,3)' 'p(1,4)' 'p(1,5)' 1}; % amplitude + spread fixed
   fixOrFree.model8 = {'p(1,1)' 'p(1,2)' 'p(1,3)' 'p(1,4)' 'p(1,5)' 1}; % all fixed 
else
   % the hypothesis demands symmetric spreads, so "left" and "right" spreads are identical
   fixOrFree.model1 = {'p(e,1)' 'p(e,2)' 'p(e,2)' 'p(1,4)' 'p(e,5)' 1}; % all free
   fixOrFree.model2 = {'p(1,1)' 'p(e,2)' 'p(e,2)' 'p(1,4)' 'p(e,5)' 1}; % mu fixed
   fixOrFree.model3 = {'p(e,1)' 'p(e,2)' 'p(e,2)' 'p(1,4)' 'p(1,5)' 1}; % amplitude fixed
   fixOrFree.model4 = {'p(e,1)' 'p(1,2)' 'p(1,2)' 'p(1,4)' 'p(e,5)' 1}; % spread fixed
   fixOrFree.model5 = {'p(1,1)' 'p(e,2)' 'p(e,2)' 'p(1,4)' 'p(1,5)' 1}; % mu + amplitude fixed
   fixOrFree.model6 = {'p(1,1)' 'p(1,2)' 'p(1,2)' 'p(1,4)' 'p(e,5)' 1}; % mu + spread fixed
   fixOrFree.model7 = {'p(e,1)' 'p(1,2)' 'p(1,2)' 'p(1,4)' 'p(1,5)' 1}; % amplitude + spread fixed
   fixOrFree.model8 = {'p(1,1)' 'p(1,2)' 'p(1,2)' 'p(1,4)' 'p(1,5)' 1}; % all fixed 
end


%% Create hypothesis structure
hyp.name = hypName;
hyp.eccModel = hypEccModel;
hyp.paramRange = paramRange;
hyp.fixOrFree = fixOrFree;
hyp.aligned = opt.aligned;
hyp.options = options;
hyp.nStartPoints = opt.nStartPoints;
