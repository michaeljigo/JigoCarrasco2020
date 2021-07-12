% Purpose:  View threshold estimates (via Psi method) on each trial during thresholding session.

function viewPsi(subj,dispFig,saveThresholds)
if ~exist('saveThresholds','var')
   saveThresholds = 0;
end

%% Load subject data
load(['../data/',subj,'/threshold/psi_method.mat']);

%% Extract and save threshold estimate from last trial
if saveThresholds
   thresh = arrayfun(@(x) x.threshold(end),pm)';
   save(['../data/',subj,'/threshold/threshEstimate.mat'],'thresh');
end

%% Plot threshold estimates
if dispFig
   ecc = stimulus.taskParams.ecc;
   sfs = stimulus.taskParams.sfs;
   for e = 1:numel(ecc)
      figure('Name',['Eccentricity ',num2str(ecc(e)),' deg']);
      for f = 1:numel(sfs)
         subplot(3,3,f);
         plot(pm(e,f).threshold,'k.-','MarkerSize',5,'Linewidth',1);
         set(gca,'box','off','TickDir','out','YLim',[-3 0],'YTick',-3:0.5:0);
         title([num2str(sfs(f)),' cpd: ',num2str(pm(e,f).threshold(end))]);
      end
   end
end
