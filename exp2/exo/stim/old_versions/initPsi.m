% Purpose:  Initialize Psi-marginal method with experimental parameters

function pm = initPsi(subj,p)

%% check if this subject already has staircase setup
threshDir = ['../data/',subj,'/threshold/'];
if exist([threshDir,'psi_method.mat'],'file')
   setupPsi = 0;
   load([threshDir,'psi_method.mat']);
else
   setupPsi = 1;
end

if setupPsi
   %% set up psi variables
   res = 20;
   ntrials = inf;
   PF = @arbLogistic;
   
   % set starting level
   stimRange = linspace(-3,0,1e2);
   [~, startIdx] = min(abs(stimRange-p.startContrast));

   % which parameters to marginalize (i.e., nuisance parameters)
   marginalize = [-1 2 3 4]; % threshold is parameter of interest
   
   %% create a structure array containing each ecc x SF combination
   % load subject data concatenated across exo and endo
   load('../../staircaseSimulations/dataPriors.mat');

   % set priors based on data
   priorGamma = 0.5;
   for e = 1:numel(p.ecc)
      for f = 1:numel(p.sfs)
         priorAlpha = linspace(min(thresh(:)),max(thresh(:)),res);
         priorBeta = linspace(min(slope(:)),max(slope(:)),res);
         priorLambda = linspace(min(lapse(:)),max(lapse(:)),res);
         
         % initialize psi method structure
         pm(e,f) = PAL_AMPM_setupPM('priorAlphaRange',priorAlpha,'priorBetaRange',priorBeta,'priorGammaRange',priorGamma,...
            'priorLambdaRange',priorLambda,'numtrials',ntrials,'PF',PF,'stimRange',stimRange,'marginalize',marginalize);
         pm(e,f).xCurrent = stimRange(startIdx);
      end
   end
end

