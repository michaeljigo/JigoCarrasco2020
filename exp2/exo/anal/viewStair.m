% Purpose:  This function will allow me to view the up-down staircases used to get
%           thresholds, and to save the threshold estimates for each condition.

function viewStair(subj,saveThresholds)
dispStair = 0;
dispCSF = 1;

%% Load subject staircase
dataDir = ['../data/',subj,'/threshold/'];
data = load([dataDir,'stair.mat']);

%% Compute thresholds from last n reversals
n = 8;
for e = 1:numel(data.stimulus.taskParams.ecc)
   for s = 1:numel(data.stimulus.taskParams.sfs)
      for l = 1:numel(data.stimulus.taskParams.stairStart)
         totalRev = max(data.stair(e,s,l).reversal);
         startRev = max(totalRev-n+1,1);
         startRev = round(totalRev*0.2);
%          startRev = 3;

         % index contrast levels between start and total reversal limits
         revIdx = ismember(data.stair(e,s,l).reversal,startRev:totalRev);

         % keep track of # of reverals that are used to compute threshold
         nRev(e,s,l) = sum(revIdx);

         % compute average contrast between start and total reversal limits
         thresh(e,s,l) = mean(data.stair(e,s,l).allLevels(revIdx));

      end
   end
end
thresh = min(thresh,[],3);

%% Save thresholds
if saveThresholds
    thresh = thresh';
    save([dataDir,'threshEstimate.mat'],'thresh');
    thresh = thresh';
end

%% Display staircases
stairCol = 'kb';
if dispStair
   for e = 1:numel(data.stimulus.taskParams.ecc)
      figure('Name',[subj,': ECC ', num2str(data.stimulus.taskParams.ecc(e))]);
      for s = 1:numel(data.stimulus.taskParams.sfs)
         subplot(3,3,s)
         for l = 1:numel(data.stimulus.taskParams.stairStart)
            plot(data.stair(e,s,l).allLevels,[stairCol(l),'.-'],'Linewidth',2); hold on
            set(gca,'YLim',[-3.2 0.2],'box','off','TickDir','out');
            xlabel('Trials'); ylabel('log contrast');
         end
         title(sprintf('%.2f cpd',data.stimulus.taskParams.sfs(s)));
      end
   end
end

%% Display CSF
if dispCSF
   figure('Name',[subj, ': CSF']);
   thresh = 1./10.^thresh;
   for e = 1:numel(data.stimulus.taskParams.ecc)
      loglog(data.stimulus.taskParams.sfs,thresh(e,:),[stairCol(e),'.-'],'MarkerSize',15,'Linewidth',2); hold on
   end
   set(gca,'YLim',[1 250],'XLim',[0.4 24],'box','off','TickDir','out','XTick',[0.5 1 2 4 8 16]);
   xlabel('Spatial frequency (cpd)'); ylabel('Sensitivity');
   legend({'4' '8'});
end
