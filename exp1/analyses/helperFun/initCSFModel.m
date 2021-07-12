% Purpose:  This function will initialize the desired CSF model for fitting purposes.
%           That is, it will initialize a structure that contains the bounds of the model.

function csf = initCSFModel(csfName,varargin)

%% Parse optional inputs
optionalIn = {'eccVal' 'sfVal' 'cueVal' 'nStartPoints'};
optionalVal = { [0 3 6 12] [0.5 1 2 4 8 11] {'neutral' 'valid'} 10};
opt = parseOptionalInputs(optionalIn,optionalVal,varargin);

%% Fitting options
options = optimoptions(@fmincon,'Algorithm','active-set','Display','none','MaxIter',1e6,...
   'FunctionTolerance',1e-6,'StepTolerance',1e-6,'MaxFunctionEvaluations',1e50);


%% Set bounds for CSF model parameters
% create matrix that will serve to index the vector of parameters for each condition
condCombos = allcomb(1:numel(opt.eccVal),1:numel(opt.cueVal));
totalCond = size(condCombos,1);

% parameters are: [shape peakSF peakCS]
switch csfName
   case 'dexp'
      % double-exponential function parameters
      nParams = 3;
      shapeBnd = [0.1 5];
      peakSF_bnd = [0.25 8];
      peakCS_bnd = [1 5e2];

      % set bounds
      lb = zeros(totalCond,nParams);
      ub = lb;
      lb(:,1) = lb(:,1)+shapeBnd(1);
      lb(:,2) = lb(:,2)+peakSF_bnd(1);
      lb(:,3) = lb(:,3)+peakCS_bnd(1);
      
      ub(:,1) = lb(:,1)+shapeBnd(2);
      ub(:,2) = lb(:,2)+peakSF_bnd(2);
      ub(:,3) = lb(:,3)+peakCS_bnd(2);
   case 'apf'
      % asymmetric parabolic function parameters
      nParams = 4;
      peakCS_bnd = [1 300];
      peakSF_bnd = [0.25 1.5];
      lowFall_bnd = [1e-4 0.5];
      highFall_bnd = [1e-4 0.5]; 

      % set bounds
      lb = zeros(totalCond,nParams);
      ub = lb;
      lb(:,1) = lb(:,1)+peakCS_bnd(1);
      lb(:,2) = lb(:,2)+peakSF_bnd(1);
      lb(:,3) = lb(:,3)+lowFall_bnd(1);
      lb(:,4) = lb(:,4)+highFall_bnd(1);
      
      ub(:,1) = ub(:,1)+peakCS_bnd(2);
      ub(:,2) = ub(:,2)+peakSF_bnd(2);
      ub(:,3) = ub(:,3)+lowFall_bnd(2);
      ub(:,4) = ub(:,4)+highFall_bnd(2);

      % log-transform parameter values
      lb = log10(lb);
      ub = log10(ub);
   case 'asymGaus'
      nParams = 4;
      peakSF_bnd = log2([0.5 8]);
      lowFall_bnd = [1 5];
      highFall_bnd = [1 5];
      peakCS_bnd = [1 500];

      % set bounds
      lb = zeros(totalCond,nParams);
      ub = lb;
      lb(:,1) = lb(:,1)+peakSF_bnd(1);
      lb(:,2) = lb(:,2)+lowFall_bnd(1);
      lb(:,3) = lb(:,3)+highFall_bnd(1);
      lb(:,4) = lb(:,4)+peakCS_bnd(1);

      ub(:,1) = ub(:,1)+peakSF_bnd(2);
      ub(:,2) = ub(:,2)+lowFall_bnd(2);
      ub(:,3) = ub(:,3)+highFall_bnd(2);
      ub(:,4) = ub(:,4)+peakCS_bnd(2);
   otherwise
      error('%s is not supported.',csfName);
end
bnd(1,:,:) = lb;
bnd(2,:,:) = ub;


%% Create csf structure
csf = opt;
csf.name = csfName;
csf.options = options;
csf.bnd = bnd;
csf.condCombos = condCombos;
csf.nParams = nParams;
