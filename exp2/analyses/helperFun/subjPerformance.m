% Purpose:  This function will parse subjects' data and compute performance across all SF and eccentricity conditions.
% Inputs:   subj = subject initials
%           whichAttn = 'endo' or 'exo'

function perfOut = subjPerformance(subj,whichAttn,varargin)

%% Parse optional inputs
optionalIn = {'nSets' 'dataDir' 'use_dprime' 'dispFig' 'figDir' 'fitCSF' 'overwritePerformance' 'bootstrapSamples' 'csfModel'};
optionalVal = {1 sprintf('../%s/data/%s/',whichAttn,subj) 1 0 sprintf('../%s/data/%s/figures/',whichAttn,subj) 1 0 1e3 'dexp'};
opt = parseOptionalInputs(optionalIn,optionalVal,varargin);

%% Bootstrap parameters
if opt.bootstrapSamples>0
   bootOpt.bootstrap = 1;
   bootOpt.bootstrapIterations = opt.bootstrapSamples;
else
   bootOpt.bootstrap = 0;
end

%% Should I run?
if opt.bootstrapSamples==0
   if opt.use_dprime
      filename = 'perf_dprime.mat';
   else
      filename = 'perf_pcorr.mat';
   end
else
   if opt.use_dprime
      filename = 'perf_dprime_bootstrap.mat';
   else
      filename = 'perf_pcorr_bootstrap.mat';
   end
end
if exist([opt.dataDir,filename],'file') && ~opt.overwritePerformance
   load([opt.dataDir,filename]);
   fprintf('Loaded performance: %s\n',[opt.dataDir,filename]);

   perfOut.sfVal = sfVal;
   perfOut.eccVal = eccVal;
   perfOut.performance = avgPerf;
   perfOut.csf = avgCSF;
   perfOut.csfParams = csfParams;
   perfOut.rt = avgRT;
   if opt.bootstrapSamples>0
      perfOut.bootstrap = perf.bootstrap;
      perfOut.bootstrap_csf = csf.bootstrap;
   end
   return
end


%% Load subject's data
% parse stim files
data = parseFiles(opt.dataDir,opt.nSets,{'tilt' 'cues' 'ecc' 'loc' 'sfs' 'accuracy' 'brokenTrial.trialIdx' 'contrast' 'response' 'reactionTime'});
% remove trials in which fixation was broken
for s = 1:opt.nSets
   data(s) = structfun(@(x) x(~data(s).trialIdx(~isnan(data(s).trialIdx))),data(s),'UniformOutput',0);

   if opt.use_dprime
      % transform tilts and responses to target present (CW; 1) and target absent (CCW; 0)
      data(s).tilt(data(s).tilt==-1) = 0;
      data(s).response(data(s).response==1) = 0;
      data(s).response(data(s).response==2) = 1;
   end
   data(s).reactionTime = abs(data(s).reactionTime);
end
% get tested SFs and ecc
sfVal = unique(data(1).sfs);
eccVal = unique(data(1).ecc);


%% Compute performance within sets
for s = 1:opt.nSets
   % create factor structures for:
   % cue
   cues.val = data(s).cues;
   cues.label = {'neutral' 'valid'};

   % sfs
   sfs.val = data(s).sfs;
   sfs.label = cellfun(@num2str,num2cell(unique(sfs.val)),'UniformOutput',0);

   % ecc
   ecc.val = data(s).ecc;
   ecc.label = cellfun(@num2str,num2cell(unique(ecc.val)),'UniformOutput',0);

   % geometric mean of RTs 
   %rt(s) = condParser(log(data(s).reactionTime),contrast,cues,sfs,ecc);
   rt(s) = condParser(log(data(s).reactionTime),cues,sfs,ecc);

   if isfield(data,{'contrast'}) && ~strcmp(subj,'MM')
      % contrast
      contrast.val = data(s).contrast;
      contrast.label = cellfun(@num2str,num2cell(unique(contrast.val)),'UniformOutput',0);

      if opt.use_dprime
         % create condition structures for target
         target.val = data(s).tilt;
         target.label = {'absent' 'present'};

         % compute d-prime
         perf(s) = condParser(data(s).response,target,cues,sfs,ecc,bootOpt);

         % Hautas, 1995 approach
         % add 0.5 to the # of hits and # of false alarms; add 1 to the # of signal and noise trials
         % take proportion and then compute d-prime
         fa_hits = cellfun(@sum, perf(s).raw)+0.5;
         noise_sig = cellfun(@numel, perf(s).raw)+1;
         perf(s).perf = fa_hits./noise_sig;

         % compute Hautas d-prime
         perf(s).perf = squeeze(diff(norminv(perf(s).perf),[],1));
        

         % compute Hautas d-prime for bootstrap samples
         if opt.bootstrapSamples>0
            boot_fa_hits = cellfun(@(x,y) x*numel(y)+0.5,perf.bootstrap,perf.raw,'UniformOutput',0);
            boot_dprime = cellfun(@(x,y) x./(numel(y)+1),boot_fa_hits,perf.raw,'UniformOutput',0);
            boot_dprime = cellfun(@(x,y) norminv(y)-norminv(x),squeeze(boot_dprime(1,:,:,:)),squeeze(boot_dprime(2,:,:,:)),'UniformOutput',0);
            perf(s).bootstrap = boot_dprime;
         end
      else
         perf(s) = condParser(data(s).accuracy,cues,sfs,ecc,bootOpt);
      end

      % store performance
      setPerf(s,:,:,:) = perf(s).perf;
      setRT(s,:,:,:) = rt(s).perf;

      % compute CSF as the average across the unique contrast values used in this set
      csf = condParser(log(data(s).contrast),sfs,ecc,bootOpt);
      %tmpCSF = cellfun(@(x) unique(x),tmpCSF.raw,'UniformOutput',0);   
      %setCSF(s,:,:) = cellfun(@(x) exp(median(x)),tmpCSF);
      setCSF(s,:,:) = exp(csf.perf);
      if opt.bootstrapSamples>0
         csf.bootstrap = cellfun(@(x) exp(x),csf.bootstrap,'UniformOutput',0);
      end
   else
      if opt.use_dprime
         % create condition structures for target
         target.val = data(s).tilt;
         target.label = {'absent' 'present'};

         % compute d-prime
         perf(s) = condParser(data(s).response,target,cues,sfs,ecc,bootOpt);

         % Hautas, 1995 approach
         % add 0.5 to the # of hits and # of false alarms; add 1 to the # of signal and noise trials
         % take proportion and then compute d-prime
         fa_hits = cellfun(@sum, perf(s).raw)+0.5;
         noise_sig = cellfun(@numel, perf(s).raw)+1;
         perf(s).perf = fa_hits./noise_sig;
         % compute Hautas d-prime
         perf(s).perf = squeeze(diff(norminv(perf(s).perf),[],1));
         
         % compute Hautas d-prime for bootstrap samples
         if opt.bootstrapSamples>0
            boot_fa_hits = cellfun(@(x,y) x*numel(y)+0.5,perf.bootstrap,perf.raw,'UniformOutput',0);
            boot_dprime = cellfun(@(x,y) x./(numel(y)+1),boot_fa_hits,perf.raw,'UniformOutput',0);
            boot_dprime = cellfun(@(x,y) norminv(y)-norminv(x),squeeze(boot_dprime(1,:,:,:)),squeeze(boot_dprime(2,:,:,:)),'UniformOutput',0);
            perf(s).bootstrap = boot_dprime;
         end
      else
         % compute proportion correct
         perf(s) = condParser(data(s).accuracy,cues,sfs,ecc,bootOpt);
      end
      % geometric mean of RTs 
      rt(s) = condParser(log(data(s).reactionTime),cues,sfs,ecc);
      setRT(s,:,:,:) = rt(s).perf;

      setPerf(s,:,:,:) = perf(s).perf;

      % get tested contrast levels for subject MM whose thresholds were not allowed to change
      tmp = load(sprintf('../%s/data/%s/threshold/threshEstimate.mat',whichAttn,subj));
      tmpCSF = tmp.thresh;
      setCSF(s,:,:) = 10.^tmpCSF;
      csf = nan;
   end
end


%% Compute performance across sets
avgPerf = squeeze(mean(setPerf,1)); 
avgCSF = squeeze(exp(median(log(setCSF),1)));
avgAttn = squeeze(diff(avgPerf,[],1));
avgRT = squeeze(exp(mean(setRT,1)));


%% Fit CSF model to contrast sensitivity values
if opt.fitCSF
   fitSF = linspace(0.25,24,1e2);

   switch opt.csfModel
      case 'dexp'
         % fit double-expponential function to contrast thresholds
         initParams = [1 2 3];
         for e = 1:size(avgCSF,2)
            csfParams(e,:) = fit_dexp2csf(sfVal,1./avgCSF(:,e)); 
         end
      case 'asymGaus'
         initParams = [1 2 2 200];
         for e = 1:size(avgCSF,2)
            csfParams(e,:) = fit_asymGaus2csf(sfVal,1./avgCSF(:,e));
         end
   end
else
   csfParams = nan;
end


%% Save data
save([opt.dataDir,filename],'avgPerf','avgCSF','sfVal','eccVal','csfParams','avgRT','perf','csf');
fprintf('Saved: %s\n',[subj,' ',filename]);
perfOut.sfVal = sfVal;
perfOut.eccVal = eccVal;
perfOut.performance = avgPerf;
perfOut.csf = avgCSF;
perfOut.csfParams = csfParams;
perfOut.rt = avgRT;
if opt.bootstrapSamples>0
   perfOut.bootstrap = perf.bootstrap;
   if strcmp(subj,'MM')
      perfOut.bootstrap_csf = [];
   else
      perfOut.bootstrap_csf = csf.bootstrap;
   end
end


%% Plot data
if opt.dispFig 
   % create figure directory
   if ~exist(opt.figDir,'dir')
      mkdir(opt.figDir);
   end
   % set colors to be used
   colors = linspecer(numel(sfVal));

   %% CSF
   figure('Name',sprintf('%s: CSF',subj));
   for e = 1:numel(eccVal)
      if opt.fitCSF
         loglog(sfVal,1./avgCSF(:,e),'.','MarkerSize',20,'Color',colors(e,:)); hold on
         fitCS = evalCSF('dexp',fitSF,csfParams(e,:));
         leg(e) = loglog(fitSF,fitCS,'-','Color',colors(e,:),'Linewidth',3);
         % mark peak SF in plot
         peakSF = csfParams(e,2);
         peakCS = evalCSF('dexp',peakSF,csfParams(e,:));
         line([peakSF peakSF],[1 peakCS],'Linestyle','-','Linewidth',2,'Color',colors(e,:));
      else
         leg(e) = loglog(sfVal,1./avgCSF(:,e),'.-','MarkerSize',20,'Color',colors(e,:),'Linewidth',3); hold on
      end
   end
   set(gca,'box','off','TickDir','out','XLim',[0.3 20],'YLim',[1 250],'YTick',[1 10 100 200]);
   xlabel('Spatial frequency (cpd)'); ylabel('Contrast sensitivity');
   legend(leg,ecc.label);
   % save figure
   saveas(gcf,sprintf('%s%s_csf.tif',opt.figDir,upper(subj)));

   %% Performance
   figure('Name',sprintf('%s: Performance',subj)); clear leg
   linestyles = {'-' ':'};
   for e = 1:numel(eccVal)
      subplot(numel(eccVal),1,e);
      for c = 1:size(avgPerf,1)
         leg(e) = semilogx(sfVal,squeeze(avgPerf(c,:,e)),'.','MarkerSize',20,'Linewidth',3,'Color',colors(e,:),...
            'Linestyle',linestyles{c}); hold on
      end
      % pretty up figure
      if opt.use_dprime
         set(gca,'box','off','TickDir','out','XLim',[0.3 20],'YLim',[0 3],'YTick',0:0.5:3,'XTick',2.^(-3:3));
         ylabel('d-prime');
      else
         % pretty up figure
         line([1e-3 30],[0.75 0.75],'Color','k','Linestyle','-','Linewidth',3);
         set(gca,'box','off','TickDir','out','XLim',[0.3 20],'YLim',[0.5 1],'YTick',0:0.1:1,'XTick',2.^(-3:3));
         ylabel('Proportion correct');
      end
      title(sprintf('%i deg',eccVal(e)));
      xlabel('Spatial frequency (cpd)');
   end
   % save figure
   if opt.use_dprime
      saveas(gcf,sprintf('%s%s_dprime.tif',opt.figDir,upper(subj)));
   else
      saveas(gcf,sprintf('%s%s_pCorr.tif',opt.figDir,upper(subj)));
   end


   %% Attention effect
   figure('Name',sprintf('%s: Attention',subj));
   for e = 1:numel(eccVal)
      subplot(numel(eccVal),1,e);
      semilogx(sfVal,avgAttn(:,e),'.-','MarkerSize',20,'Linewidth',3,'Color',colors(e,:)); hold on

      % pretty up figure
      title(sprintf('%i deg',eccVal(e)));
      if opt.use_dprime
         set(gca,'box','off','TickDir','out','XLim',[0.3 20],'YLim',[-2 2],'YTick',-2:0.5:2,'XTick',2.^(-3:3));
      else
         set(gca,'box','off','TickDir','out','XLim',[0.3 20],'YLim',[-0.2 0.2],'YTick',-0.5:0.1:0.5,'XTick',2.^(-3:3));
      end
      line([1e-3 30],[0 0],'Color','k','Linestyle','-','Linewidth',3);
      xlabel('Spatial frequency (cpd)'); ylabel('Attention effect');
   end
   % save figure
   if opt.use_dprime
      saveas(gcf,sprintf('%s%s_attn_dprime.tif',opt.figDir,upper(subj)));
   else
      saveas(gcf,sprintf('%s%s_attn.tif',opt.figDir,upper(subj)));
   end


   %% Aligned attention effect
   figure('Name',sprintf('%s: Aligned attention',subj));
   % get peak SF based on data
   [~,peak] = min(avgCSF);
   for e = 1:numel(eccVal)
      subplot(numel(eccVal),1,e);

      % get value of peak SF
      peakSF = sfVal(peak(e));

      % align SFs relative to peak SF
      alignedSF = log2(sfVal)-log2(peakSF);

      % plot aligned attention effect
      plot(alignedSF,avgAttn(:,e),'.-','MarkerSize',20,'Linewidth',3,'Color',colors(e,:)); hold on

      % pretty up figure
      title(sprintf('%i deg',eccVal(e)));
      if opt.use_dprime
         set(gca,'box','off','TickDir','out','XLim',[-5 5],'YLim',[-1 1],'YTick',-2:0.5:2,'XTick',-5:5);
      else
         set(gca,'box','off','TickDir','out','XLim',[-5 5],'YLim',[-0.2 0.2],'YTick',-0.5:0.1:0.5,'XTick',-5:5);
      end
      line([-30 30],[0 0],'Color','k','Linestyle','-','Linewidth',3);
      line([0 0],[-10 10],'Color','k','Linestyle','-','Linewidth',3);
      xlabel('delta peakSF (octaves)'); ylabel('Attention effect');
   end 
   % save figure
   if opt.use_dprime
      saveas(gcf,sprintf('%s%s_aligned_attn_dprime.tif',opt.figDir,upper(subj)));
   else
      saveas(gcf,sprintf('%s%s_aligned_attn.tif',opt.figDir,upper(subj)));
   end
end
