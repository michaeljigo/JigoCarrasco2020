% Purpose:  Fit full model to individual subject dataset. Full model entails that parameters for all components - 
%           Contrast Response Function (CRF), Contrast Sensitivity Function (CSF), and attention modulation profile - will be fit simultaneously. 
%           Fit will be optimized via Maximum Likelihood Estimation (MLE), in practice we will minimize the negative log likelihood.
%        
%           Each iteration of the fit will proceed as follows:
%           1. Functional form of the CSF (currently asymmetric Gaussian) will determine Neutral contrast sensitivity (CS) for tested spatial frequencies (SFs).
%           2. Valid CS created by modulating Neutral CS by attention profile (symmetric, skewed, uniform).
%           3. Neutral and Valid CS will be inverted and serve as contrast threshold parameter for respective CRF.
%           4. CRF (currently logistic function) will have a single slope across SFs within an eccetricity and lapse will be fixed across cues.
%           5. Negative log-likelihood will be computed and parameter estimates updated.
%           
%           Schematic is represented in Figure 2.

function fit_subjFullModel(subj,whichAttn,varargin)
%addpath(genpath('~/apps'));
addpath(genpath('./helperFun'));

%% Parse optional inputs
optionalIn = {'dataDir' 'use_dprime' 'nStartPoints' 'dispFig' 'removeCeiling' 'overwritePerformance' 'overwriteFit' 'csfShape' 'crfShape' 'attnShape' 'crfModelNum' 'attnModelNum' 'bootstrapSamples'};
optionalVal = {sprintf('../%s/data/%s/',whichAttn,subj) 1 10 0 0 0 0 'dexp' 'nakarushton' 'symmetric' 5 1 0};
opt = parseOptionalInputs(optionalIn,optionalVal,varargin);
opt.subj = subj;


%% Load data files and compute performance
data = load_and_parse_files(opt);

%% Should I fit?
saveDir = [opt.dataDir,'fullModel/'];
if ~exist(saveDir,'dir')
   mkdir(saveDir);
end
if opt.use_dprime
   filename = sprintf('fitParameters_%s_%s%i_%s%i_dprime_v2.mat',opt.csfShape,opt.crfShape,opt.crfModelNum,opt.attnShape,opt.attnModelNum);
else
   filename = sprintf('fitParameters_%s_%s%i_%s%i_pcorr.mat',opt.csfShape,opt.crfShape,opt.crfModelNum,opt.attnShape,opt.attnModelNum);
end
if exist([saveDir,filename],'file') && ~opt.overwriteFit
   load([saveDir,filename]);
   fprintf('Loaded fit: %s\n',[saveDir,filename]);
   doFit = 0;
else
   doFit = 1;
end


%% Initialize parameters for each component of model (CSF, Attention, CRF)
if doFit
   [csf attn crf] = init_full_parameters(data,opt);

   % vectorize parameters for input into fitting function
   [init bnd] = vectorize_parameters(csf,attn,crf);
   fprintf('Parameters initialized.\n');
   

   %% Do fitting
   fprintf('Optimization begins...\n');
   % initialize fitting options
   options = optimoptions(@fmincon,'Algorithm','interior-point','Display','off','MaxIter',1e3,'FunctionTolerance',1e-6,'StepTolerance',1e-12,'MaxFunctionEvaluations',1e50);
   
   % set up solver
   fitFun = @(params)full_model_objective(data,csf,attn,crf,params);
   problem = createOptimProblem('fmincon','objective',fitFun,'x0',init,'lb',bnd(:,1),'ub',bnd(:,2),'options',options);
   ms = MultiStart('FunctionTolerance',1e-8,'XTolerance',1e-8,'Display','off','StartPointsToRun','bounds','UseParallel',0);
   stpoints = RandomStartPointSet('NumStartPoints',opt.nStartPoints,'ArtificialBound',500);
   [params cost] = run(ms,problem,stpoints);
   % re-structure parameters
   [~,~,csf,attn,crf] = vectorize_parameters(csf,attn,crf,params);

   % save fitted parameters
   save([saveDir,filename],'csf','attn','crf','cost','data');
   fprintf('Saved fit: %s\n',[saveDir,filename]);
end
