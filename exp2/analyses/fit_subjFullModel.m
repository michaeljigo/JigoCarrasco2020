% Purpose:  Fit SF gain profile to the cueing effect in the distractor experiment. 
% By:       Michael Jigo

function fit_subjFullModel(subj,whichAttn,varargin)
addpath(genpath('./helperFun'));

%% Parse optional inputs
optionalIn = {'dataDir' 'nStartPoints' 'attnShape' 'attnModelNum' 'overwritePerformance' 'overwriteFit' 'dispFig' 'bootstrapSamples'};
optionalVal = {sprintf('../%s/data/%s/',whichAttn,subj) 30 'uniform' 1 0 0 0 0};
opt = parseOptionalInputs(optionalIn,optionalVal,varargin);
opt.use_dprime = 1;


%% Load data files and compute performance
data = subjPerformance(subj,whichAttn,'overwritePerformance',opt.overwritePerformance,'use_dprime',opt.use_dprime,'bootstrapSamples',opt.bootstrapSamples);
% remove highest tested spatial frequency
data.sfVal(end) = [];
data.performance(:,end,:) = [];
data.rt(:,end,:) = [];
data.csf(end,:) = [];


%% Should I fit?
saveDir = [opt.dataDir,'fullModel/'];
if ~exist(saveDir,'dir')
   mkdir(saveDir);
end
filename = sprintf('fitParameters_%s%i_dprime_v2.mat',opt.attnShape,opt.attnModelNum);
if exist([saveDir,filename],'file') && ~opt.overwriteFit
   load([saveDir,filename]);
   fprintf('Loaded fit: %s\n',[saveDir,filename]);
   doFit = 0;
else
   doFit = 1;
end

if doFit
   %% Initialize parameters for each component of model (Attention)
   attn = init_full_parameters(data,opt);

   % vectorize parameters for input into fitting function
   [init bnd] = vectorize_parameters(attn);
   fprintf('Parameters initialized.\n');


   %% Do fitting
   fprintf('Optimization begins...\n');
   % initialize fitting options
   options = optimoptions(@fmincon,'Algorithm','active-set','Display','none','MaxIter',1e6,'FunctionTolerance',1e-6,'StepTolerance',1e-10,'MaxFunctionEvaluations',1e50);
      
   % set up solver
   fitFun = @(params)full_model_objective(data,attn,params);
   problem = createOptimProblem('fmincon','objective',fitFun,'x0',init,'lb',bnd(:,1),'ub',bnd(:,2),'options',options);
   ms = MultiStart('FunctionTolerance',1e-10,'XTolerance',1e-6,'Display','off','StartPointsToRun','bounds','UseParallel',0);
   [params cost] = run(ms,problem,opt.nStartPoints);
   % re-structure parameters
   [~,~,attn] = vectorize_parameters(attn,params);
   
   % save fitted parameters
   nParams = 6;
   save([saveDir,filename],'attn','cost','data','nParams');
   fprintf('Saved fit: %s\n',[saveDir,filename]);
end
