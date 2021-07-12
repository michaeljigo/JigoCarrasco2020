% Compute CSF using an arbitrary number of sets for each subject.

function fit_subjCSF(subj,whichAttn,varargin)
addpath(genpath('./helperFun'));

%% Parse optional inputs
optionalIn = {'nSets' 'dataDir' 'figDir' 'fitCSF' 'csfModel'};
optionalVal = {3 sprintf('../%s/data/%s/',whichAttn,subj) sprintf('../%s/data/%s/figures/',whichAttn,subj) 1 'dexp'};
opt = parseOptionalInputs(optionalIn,optionalVal,varargin);


%% Load subject's data
% parse stim files
data = parseFiles(opt.dataDir,opt.nSets,{'tilt' 'cues' 'ecc' 'loc' 'sfs' 'accuracy' 'brokenTrial.trialIdx' 'contrast' 'response' 'reactionTime'});
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

   if isfield(data,{'contrast'}) && ~strcmp(subj,'MM')
      % contrast
      contrast.val = data(s).contrast;
      contrast.label = cellfun(@num2str,num2cell(unique(contrast.val)),'UniformOutput',0);

      % compute CSF as the average across the unique contrast values used in this set
      tmpCSF = condParser(log(data(s).contrast),sfs,ecc);
      %tmpCSF = cellfun(@(x) unique(x),tmpCSF.raw,'UniformOutput',0);   
      %setCSF(s,:,:) = cellfun(@(x) exp(median(x)),tmpCSF);
      setCSF(s,:,:) = exp(tmpCSF.perf);
   else
      % get tested contrast levels for subject MM whose thresholds were not allowed to change
      tmp = load(sprintf('../%s/data/%s/threshold/threshEstimate.mat',whichAttn,subj));
      tmpCSF = tmp.thresh;
      setCSF(s,:,:) = 10.^tmpCSF;
   end
end

%% Compute performance across sets
avgCSF = squeeze(exp(mean(log(setCSF),1)));


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
   end
else
   csfParams = nan;
end
%% Save data
save(sprintf('%scsf_%s.mat',opt.dataDir,opt.csfModel),'avgCSF','sfVal','eccVal','csfParams');
fprintf('Saved: %s CSF\n',subj);
