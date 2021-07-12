% Purpose:  Recreate Figure 5. 
%           AIC model comparisons of attention SF profiles fit to endogenous and exogenous attention data.
%
% By:       Michael Jigo
% Edited:   06.22.21

function figure5
addpath(genpath('./helperFun'));
opt.attnShapes = {'symmetric' 'uniform'};
opt.attnType   = {'exo' 'endo'};


%% Load the log-likelihood and # of parameters for each observer and model
subjList = {'AB' 'AF' 'AS' 'LH' 'LS' 'MJ' 'RF' 'SC' 'SX'};
for s = 1:numel(subjList)
   subjLL = []; % LL = log-likelihood
   subjParams = [];
   for at = 1:numel(opt.attnType)
      for a = 1:numel(opt.attnShapes)
         % get filenames
         dataDir = sprintf('../%s/data/%s/fullModel/',opt.attnType{at},subjList{s});
         files = dir(sprintf('%sfitParameters_dexp_nakarushton5_%s1_dprime.mat',dataDir,opt.attnShapes{a}));
         
         % load and store sse and # of parameters
         data = load([dataDir,files.name]);

         % get # of parameters for the given model
         nParams = vectorize_parameters(data.csf,data.attn,data.crf);
         nParams = numel(nParams);
         modelLL(s,at,a) = data.cost;
         modelParams(s,at,a) = nParams;
      end
   
   % # of observations corresponds to the # of contrast levels tested
   subjObservations(s,at,:) = repmat(data.data.nObservations,1,numel(opt.attnShapes));
   end
end

%% Convert negative log-likelihood to AICc
aic = subjObservations.*log(modelLL./subjObservations)+(2*(modelParams+1));

% set AIC to be relative to the symmetric profile
aic = aic-aic(:,:,1);
aic = squeeze(aic(:,:,2));


%% Plot group-average AIC values 
avgAIC = mean(aic);
semAIC = std(aic,[],1)./sqrt(numel(subjList));
semAIC = withinSubjError(aic,0);
figure('Name',sprintf('Exp1: Model Comparison'),'position',[680 671 261 277]);
bar(1,avgAIC(1),'FaceColor',[5 113 176]./255,'edgecolor','none'); hold on
bar(2,avgAIC(2),'FaceColor',[202 0 32]./255,'edgecolor','none'); hold on
errorbar(1:2,avgAIC,semAIC,'Color','k','Linestyle','none','CapSize',0);
set(gca,'xticklabel',opt.attnType,'box','off','tickdir','out','xlim',[0.5 2.5],'xtick',[1 2],'ylim',[-4 4],'ytick',-10:2:10);
ylabel('AIC_{Plateau}-AIC_{Gaussian}','fontname','arial','fontsize',10);
figureDefaults
