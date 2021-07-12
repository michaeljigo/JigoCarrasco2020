function pCorr_distractTask(subj,updateThresh,nSets)

if ~exist('updateThresh','var')
   updateThresh = 0;
end

if ~exist('nSets','var')
   nSets = 1;
end

%% Load data
if updateThresh
   % load contrast levels
   thresh = load(['../data/',subj,'/threshold/threshEstimate.mat']);
   dataDir = ['../data/',subj,'/homo/tmp/'];
else
   dataDir = ['../data/',subj,'/homo/'];
end
data = parseFiles(dataDir,nSets,{'tilt' 'cues' 'ecc' 'loc' 'sfs' 'accuracy' 'brokenTrial.trialIdx' 'contrast' 'response'});

% remove trials that were broken
for s = 1:nSets
   data(s) = structfun(@(x) x(~data(s).trialIdx(~isnan(data(s).trialIdx))),data(s),'UniformOutput',0);
end

% get stimulus parameters
sfVal = unique(data(1).sfs);
eccVal = unique(data(1).ecc);

%% Compute performance for each set of blocks
for s = 1:nSets
   % cue
   cues.val = data(s).cues;
   cues.label = {'neutral' 'valid'};

   % sfs
   sfs.val = data(s).sfs;
   sfs.label = cellfun(@num2str,num2cell(unique(sfs.val)),'UniformOutput',0);

   % ecc
   ecc.val = data(s).ecc;
   ecc.label = cellfun(@num2str,num2cell(unique(ecc.val)),'UniformOutput',0);

   % hemi
   hemi.val = data(s).loc;
   hemi.label = {'left' 'right'};

   % contrast
   contrast.val = data(s).contrast;
   contrast.label = cellfun(@num2str,num2cell(unique(contrast.val)),'UniformOutput',0);
   
   % compute proportion correct
   perf(s) = condParser(data(s).accuracy,contrast,cues,sfs,ecc);

   perf(s).perf = squeeze(nanmean(perf(s).perf,1));

   % compute CSF
   if isfield(data(s),{'contrast'})
      csf(s) = condParser(data(s).contrast,sfs,ecc);
   else
      csf(s).perf = 0;
   end
   %csf(s).perf = exp(csf(s).perf);
   
   if updateThresh
      % update thresholds based on neutral performance across all previous blocks 
      neut = squeeze(perf(s).perf(1,:,:));

      % thresholds will be updated if performance is below 70% or exceeds 80% 
      perfDiff = (0.75-neut)*100;
      %perfDiff(abs(perfDiff)<=5) = 0;

      % for every percentage of performance difference, change threshold by 0.0125 log units 
      % (this corresponds to 0.1 log units per 8% difference, as gauged from expeirmental data from "poster" experiment) 
      threshChange = perfDiff*0.0125;
      thresh = thresh.thresh+threshChange;

      % save updated thresholds and exit analysis program
      save(['../data/',subj,'/threshold/threshEstimate.mat'],'thresh');
      return
   end
   % store performance and CSF on each set
   setPerf(s,:,:,:) = perf(s).perf;
   setCSF(s,:,:) = csf(s).perf;
   
   
   %% compute d-prime
   % transform tilts and responses to target present (CW; 1) and target absent (CCW; 0)
   data(s).tilt(data(s).tilt==-1) = 0;
   data(s).response(data(s).response==1) = 0;
   data(s).response(data(s).response==2) = 1;
      
   % target
   target.val = data(s).tilt;
   target.label = {'absent' 'present'};
      
   % compute d-prime
   dp(s) = condParser(data(s).response,target,cues,sfs,ecc);
   tmp = squeeze(diff(norminv(dp.perf),[],1));
   dPrime(s,:,:,:) = tmp;
end

%% Compute average across sets
avgPerf = squeeze(mean(setPerf,1));
%avgPerf = squeeze(mean(dPrime,1));
stdPerf = squeeze(std(setPerf,[],1));
avgCSF = squeeze(exp(mean(log(setCSF),1)));
if all(avgCSF(:)==0)
   avgCSF = load(['../data/',subj,'/threshold/threshEstimate.mat']);
   avgCSF = 10.^avgCSF.thresh;
end

% compute error across attention effects
stdEffect = setPerf(:,2:end,:,:)-setPerf(:,1,:,:);
stdEffect = squeeze(std(stdEffect,[],1));



%% Plot performance
cueCol = 'kbrm'; clear leg
cueLines = {'-' '-' '-' '-'};
% Proportion correct plot
figure('Name',[subj,': Neutral & Attention']);
for e = 1:numel(eccVal)
   subplot(1,numel(eccVal),e);
   for c = 1:numel(cues.label)
      %for s = 1:nSets
         %scatter(sfVal,squeeze(setPerf(s,c,:,e)),10+(c-1)*2,'MarkerFaceColor','none','MarkerEdgeColor',cueCol(c),'MarkerFaceAlpha',0.7); hold on
      %end

      % plot average across sets
      leg(c) = semilogx(sfVal,squeeze(avgPerf(c,:,e)),[cueCol(c),'-'],'Linewidth',2); hold on
      %errorbar(sfVal,squeeze(avgPerf(c,:,e)),squeeze(stdPerf(c,:,e)),'Color',cueCol(c),'Linestyle','none','Linewidth',2);

      % pretty up figures
      set(gca,'XTick',2.^(-2:3),'XLim',[0.3 20],'YLim',[0 1],'box','off','TickDir','out','YTick',0:0.25:1,'XScale','log');
      xlabel('Spatial frequency (cpd)'); ylabel('Proportion correct');
      line([0.3 20],[0.75 0.75],'Color','g','Linestyle','-');
   end
   title([num2str(eccVal(e)),' deg']);
end
legend(leg,cues.label); clear leg
return


%% Non-aligned attention effect
figure('Name',[subj,': Attention effect']); leg = [];
for e = 1:numel(eccVal)
   subplot(1,numel(eccVal),e);
   for c = 2:size(avgPerf,1)
      %for s = 1:nSets
         %scatter(sfVal,squeeze(setPerf(s,c,:,e)-setPerf(s,1,:,e)),10+(c-1)*2,'MarkerFaceColor','none','MarkerEdgeColor',cueCol(c),'MarkerFaceAlpha',0.7); hold on
      %end

      % plot average across sets
      leg(c) = semilogx(sfVal,squeeze(avgPerf(c,:,e)-avgPerf(1,:,e)),[cueCol(c),'-'],'Linewidth',2); hold on
      %errorbar(sfVal,squeeze(avgPerf(c,:,e)-avgPerf(1,:,e)),squeeze(stdEffect(:,e)),'Linestyle','none','Color',cueCol(c),'Linewidth',2);

      % pretty up figure
      line([1e-3 20],[0 0],'Color','k','Linestyle','-');
      set(gca,'XTick',2.^(-2:3),'XLim',[0.3 20],'YLim',[-0.1 0.1],'box','off','TickDir','out','YTick',-1.25:0.1:1.25,'XScale','log');
      xlabel('Spatial frequency (cpd)'); ylabel('Attention-Neutral');
   end
   title([num2str(eccVal(e)),' deg']);
end
legend(leg(2:end),cues.label(2:end));



%% Plot CSF
initParams = [2 4 2e2]; fitX = linspace(0.4,20,1e2);
linestyles = {'-' '--'};
figure('Name',[subj,': CSF']); clear leg
for e = 1:numel(eccVal)
   leg(e) = loglog(sfVal,1./avgCSF(:,e),[cueCol(e),'.-'],'MarkerSize',15,'Linewidth',2); hold on

   % fit a double-exponential function to capture the CSF
   %params = fitCSF2Data(sfVal,1./avgCSF(:,e),initParams); hold on

   % plot fit to CSF
   %fitY = evalCSF('dexp',fitX,params);
   %loglog(fitX,fitY,[cueCol(e),'-'],'Linewidth',2);

   % set peaks to be the tested point nearest to the fitted point
   %[~,peak(e)] = min(abs(log2(sfVal)-log2(params(2))));

   % plot vertical line at peak SF
   %line([params(2) params(2)],[1 max(fitY)],'Color',cueCol(e),'Linewidth',2);

   %%% TEMPORARY
   %avgCSF(peak(e),e) = min(avgCSF(e,:));
end
% pretty up figure
set(gca,'XTick',2.^(-2:3),'XLim',[0.3 20],'YLim',[1 250],'box','off','TickDir','out','YTick',[1 10 100 200]);
xlabel('Spatial frequency (cpd)'); ylabel('Sensitivity');
legend(leg, ecc.label);


%% Save performance for group results
save([dataDir,'perf.mat'],'perf','avgPerf','avgCSF','sfVal','eccVal');

%% Aligned attention effect
figure('Name',[subj,': Aligned attention effect']); clear leg
[~,peak] = min(avgCSF);
for e = 1:numel(eccVal)
   subplot(1,numel(eccVal),e);
   for c = 2:size(avgPerf,1)
      % find peak SF in neutral condition
      peakSF = sfVal(peak(e));

      % align SFs relative to peak
      alignSF = log2(sfVal)-log2(peakSF);

      % plot attention effect as a function of aligned SF
      %for s = 1:nSets
         %scatter(alignSF,squeeze(setPerf(s,c,:,e)-setPerf(s,1,:,e)),10+(c-1)*5,'MarkerFaceColor','none','MarkerEdgeColor',cueCol(c),'MarkerFaceAlpha',0.7); hold on
      %end
      % average across sets
      leg(c) = plot(alignSF,squeeze(avgPerf(c,:,e)-avgPerf(1,:,e)),[cueCol(c),'-'],'Linewidth',2); hold on
      %errorbar(alignSF,squeeze(avgPerf(c,:,e)-avgPerf(1,:,e)),squeeze(stdEffect(:,e)),'Linestyle','none','Color',cueCol(c),'Linewidth',2);
   end
   line([-10 10],[0 0],'Color','k','Linestyle','-'); line([0 0],[-5 5],'Color','k','Linestyle','-');
   set(gca,'XTick',-4:4,'XLim',[-4.005 4.005],'YLim',[-0.1 0.1],'box','off','TickDir','out','YTick',-1.25:0.1:1.25);
   xlabel('delta peakSF (octaves)'); ylabel('Attention-Neutral');
   title([num2str(eccVal(e)),' deg']);
end
legend(leg(2:end),cues.label(2:end));



%% Fitting function
function p = fitCSF2Data(sfs,cs,init)
% fitting options
options = optimoptions(@fmincon,'Algorithm','interior-point','Display','none','MaxIter',1e3,'functionTolerance',1e-14,'StepTolerance',1e-14,'MaxfunctionEvaluations',1e50);
ms = MultiStart('XTolerance',1e-5,'Display','off','StartPointsToRun','bounds','UseParallel',1);

% create fitting anonymous function
fitFun = @(p) sqrt(mean((log(cs)-log(evalCSF('dexp',sfs,p))').^2));
modelProb = createOptimProblem('fmincon','objective',fitFun,'x0',init,'lb',[0 0.1 1],'ub',[1e2 16 3e2],'options',options);
[p trainErr] = run(ms,modelProb,10);

