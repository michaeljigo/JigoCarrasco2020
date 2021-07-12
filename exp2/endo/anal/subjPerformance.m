% Purpose:  This function will parse subjects' data and compute performance across all SF and eccentricity conditions.

function subjPerformance(subj,varargin)

%%% Parse optional inputs
optionalIn = {'nSets' 'dataDir' 'use_dprime' 'dispFig' 'figDir'};
optionalVal = {1 sprintf('../data/%s/homo/',subj) 0 1 sprintf('../data/%s/figures/',subj)};
opt = parseOptionalInputs(optionalIn,optionalVal,varargin);


%% Load subject's data
% parse stim files
data = parseFiles(opt.dataDir,opt.nSets,{'tilt' 'cues' 'ecc' 'loc' 'sfs' 'accuracy' 'brokenTrial.trialIdx' 'contrast' 'response'});
% remove trials in which fixation was broken
for s = 1:opt.nSets
   data(s) = structfun(@(x) x(~data(s).trialIdx(~isnan(data(s).trialIdx))),data(s),'UniformOutput',0);
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

   if isfield(data,{'contrast'})
      % contrast
      contrast.val = data(s).contrast;
      contrast.label = cellfun(@num2str,num2cell(unique(contrast.val)),'UniformOutput',0);

      % compute proportion correct
      perf(s) = condParser(data(s).accuracy,contrast,cues,sfs,ecc);

      % compute average performance across contrast levels
      setPerf(s,:,:,:) = squeeze(nanmean(perf.perf,1));

      % compute CSF as the average across the unique contrast values used in this set
      tmpCSF = condParser(data.contrast,sfs,ecc);
      tmpCSF = cellfun(@(x) unique(x),tmpCSF.raw,'UniformOutput',0);   
      setCSF(s,:,:) = cellfun(@(x) exp(median(log(x))),tmpCSF);
   else
      % compute proportion correct
      perf(s) = condParser(data(s).accuracy,cues,sfs,ecc);
      setPerf(s,:,:,:) = perf(s).perf;

      % get tested contrast levels for subject MM whose threshold was not allowed to change
      tmp = load(['../data/',subj,'/threshold/threshEstimate.mat']);
      tmpCSF(1,:,:) = tmp.thresh;
      tmpCSF(2,:,:) = viewPsi(subj,0,0);
      setCSF(s,:,:) = squeeze(10.^mean(tmpCSF));
   end
end


%% Compute performance across sets
avgPerf = squeeze(mean(setPerf,1)); 
avgCSF = squeeze(exp(median(log(setCSF),1)));
avgAttn = squeeze(diff(avgPerf,[],1));


%% Save data
save([opt.dataDir,'perf.mat'],'avgPerf','avgCSF','sfVal','eccVal');
fprintf('Saved: %s\n',subj);


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
      leg(e) = loglog(sfVal,1./avgCSF(:,e),'.-','MarkerSize',20,'Color',colors(e,:),'Linewidth',3); hold on
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
      title(sprintf('%i deg',eccVal(e)));
      line([1e-3 30],[0.75 0.75],'Color','k','Linestyle','-','Linewidth',3);
      set(gca,'box','off','TickDir','out','XLim',[0.3 20],'YLim',[0.5 1],'YTick',0:0.1:1,'XTick',2.^(-3:3));
      xlabel('Spatial frequency (cpd)'); ylabel('Proportion correct');
   end
   % save figure
   saveas(gcf,sprintf('%s%s_pCorr.tif',opt.figDir,upper(subj)));


   %% Attention effect
   figure('Name',sprintf('%s: Attention',subj));
   for e = 1:numel(eccVal)
      subplot(numel(eccVal),1,e);
      semilogx(sfVal,avgAttn(:,e),'.-','MarkerSize',20,'Linewidth',3,'Color',colors(e,:)); hold on

      % pretty up figure
      title(sprintf('%i deg',eccVal(e)));
      line([1e-3 30],[0 0],'Color','k','Linestyle','-','Linewidth',3);
      set(gca,'box','off','TickDir','out','XLim',[0.3 20],'YLim',[-0.2 0.2],'YTick',-0.5:0.1:0.5,'XTick',2.^(-3:3));
      xlabel('Spatial frequency (cpd)'); ylabel('Attention effect');
   end
   % save figure
   saveas(gcf,sprintf('%s%s_attn.tif',opt.figDir,upper(subj)));


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
      line([-30 30],[0 0],'Color','k','Linestyle','-','Linewidth',3);
      line([0 0],[-10 10],'Color','k','Linestyle','-','Linewidth',3);
      set(gca,'box','off','TickDir','out','XLim',[-5 5],'YLim',[-0.2 0.2],'YTick',-0.5:0.1:0.5,'XTick',-5:5);
      xlabel('delta peakSF (octaves)'); ylabel('Attention effect');
   end 
   % save figure
   saveas(gcf,sprintf('%s%s_aligned_attn.tif',opt.figDir,upper(subj)));
end
