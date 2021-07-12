% Purpose:  Analyze the verifyThresh session.

function verifyThresh(subj,nSets)

%% Load subject data
dataDir = ['../data/',subj,'/threshold/verifyThresh/'];
nFiles = numel(dir([dataDir,'*stim*'])); if ~exist('nSets','var'), nSets = round(nFiles/4); end
data = parseFiles(dataDir,nSets,{'ecc' 'loc' 'sfs' 'accuracy' 'brokenTrial.trialIdx','contrast'});

%% Compute performance for each set
for s = 1:numel(data)
   % remove trials that were broken
   data(s).trialIdx(end) = 0;
   data(s) = structfun(@(x) x(~data(s).trialIdx & ~isnan(data(s).trialIdx)),data(s),'UniformOutput',0);
   
   % sfs
   sfs.val = data(s).sfs;
   sfs.label = cellfun(@num2str,num2cell(unique(sfs.val)),'UniformOutput',0);
   sfVal = unique(sfs.val);

   % ecc
   ecc.val = data(s).ecc;
   ecc.label = cellfun(@num2str,num2cell(unique(ecc.val)),'UniformOutput',0);
   eccVal = unique(ecc.val);

   % compute proportion correct
   perf(s) = condParser(data(s).accuracy,sfs,ecc);

   % compute average contrast value
   con(s) = condParser(data(s).contrast,sfs,ecc);
end

%% Plot results
eccCol = 'krb';
% performance
figure('Name',[subj,': verifyThresh']);
for s = 1:numel(data)
   subplot(1,numel(data),s)
   semilogx(sfVal,perf(s).perf(:,1),['k.-'],'MarkerSize',15,'Linewidth',2); hold on
   semilogx(sfVal,perf(s).perf(:,2),['b.-'],'MarkerSize',15,'Linewidth',2); hold on
   title(['Set ',num2str(s)]);
   set(gca,'XTick',2.^(-2:4),'XLim',[0.4 20],'YLim',[0 1],'box','off','TickDir','out','YTick',0:0.2:1);
   xlabel('Spatial frequency (cpd)'); ylabel('Proportion correct');
   hline(0.75,'r--');
   hline(0.5,'k--');
end

% thresholds
figure('Name',[subj,': verified CSF']);
for s = 1:numel(data)
   subplot(1,numel(data),s)
   con(s).perf(con(s).perf>0) = 0;
   loglog(sfVal,1./10.^(con(s).perf(:,1)),'k.-','MarkerSize',20,'Linewidth',2); hold on
   loglog(sfVal,1./10.^(con(s).perf(:,2)),'b.-','MarkerSize',20,'Linewidth',2);
   title(['Set ',num2str(s)]);
   set(gca,'XTick',2.^(-2:4),'XLim',[0.4 20],'YLim',[1 250],'box','off','TickDir','out','YTick',[1 10 100 200]);
   xlabel('Spatial frequency (cpd)'); ylabel('Sensitivitiy');
end

% ask if new thresholds should be saved
saveThresh = input('Which set to save? ');
if saveThresh
   thresh = con(saveThresh).perf;
   save(['../data/',subj,'/threshold/threshEstimate.mat'],'thresh');
end
