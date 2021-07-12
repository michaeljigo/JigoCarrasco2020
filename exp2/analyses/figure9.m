% Purpose:  Recreate Figure 9. 
%           AIC model comparisons of attention SF profiles fit to endogenous and exogenous attention data in Experiment 2.
%
% By:       Michael Jigo
% Edited:   06.29.21

function figure9
addpath(genpath('./helperFun'));
opt.attnShapes = {'symmetric' 'uniform'};
opt.attnType   = {'exo' 'endo'};

%% Load the SSE and # of parameters for each observer and model
   subjList = {'AS' 'DT' 'KT' 'MJ' 'MM' 'RF' 'SO' 'SP' 'SX' 'YS'};

   for s = 1:numel(subjList)
      subjSSE = []; subjParams = [];
      for at = 1:numel(opt.attnType)
         for a = 1:numel(opt.attnShapes)
            % get filenames
            dataDir = sprintf('../%s/data/%s/fullModel/',opt.attnType{at},subjList{s});
            files = dir(sprintf('%sfitParameters_%s1_dprime.mat',dataDir,opt.attnShapes{a}));
               
            % load and store sse and # of parameters
            data = load([dataDir,files.name]);
            modelSSE(s,at,a) = data.cost;
            modelParams(s,at,a) = data.nParams;
         end
      end
   end

   
%% Convert SSE to AICc
   nObservations = 16;
   aic = nObservations.*log(modelSSE./nObservations)+(2*modelParams);

   % set aic to be relative to symmetric
      aic = aic-aic(:,:,1);
      aic = squeeze(aic(:,:,2));


%% Plot group-average AIC values 
   avgAIC = mean(aic);
   semAIC = withinSubjError(aic,1);
   figure('Name',sprintf('Exp2: Model Comparison'),'position',[360 416 261 277]);
   bar(1,avgAIC(1),'FaceColor',[5 113 176]./255,'edgecolor','none'); hold on
   bar(2,avgAIC(2),'FaceColor',[202 0 32]./255,'edgecolor','none'); hold on
   errorbar(1:2,avgAIC,semAIC,'Color','k','Linestyle','none','CapSize',0);
   set(gca,'xticklabel',opt.attnType,'box','off','tickdir','out','xlim',[0.5 2.5],'xtick',[1 2],'ylim',[-4 4],'ytick',-10:2:10);
   ylabel('AIC_{Plateau}-AIC_{Gaussian}','fontname','arial','fontsize',10);
   figureDefaults
