% Purpose:  Load stim files in data directory and parse stimulus conditions for use in fitting psychometric functions. Then, compute performance for 
%           each condition. If specified, convert proportion correct to d-prime.

function data = load_and_parse_files(opt)

%% Should I run?
saveDir = [opt.dataDir,'fullModel/'];
if opt.bootstrapSamples==0
   if opt.use_dprime
      filename = 'performance_dprime.mat';
   else
      filename = 'performance_pcorr.mat';
   end
   bootOpt.bootstrap = 0;
else
   if opt.use_dprime
      filename = 'performance_dprime_bootstrap.mat';
   else
      filename = 'performance_pcorr_bootstrap.mat';
   end
   bootOpt.bootstrap = 1;
   bootOpt.bootstrapIterations = opt.bootstrapSamples;
end

if exist([saveDir,filename],'file') && ~opt.overwritePerformance
   load([saveDir,filename]);
   fprintf('Loaded performance: %s\n',[saveDir,filename]);
   return
end


%% Load and parse files
[parsed f] = parseFiles(opt.dataDir,1,{'parameter' 'tilt' 'cues' 'ecc' 'loc' 'sfs' 'contrast' 'accuracy' 'brokenTrial.trialIdx' 'contrastVal' 'response'});

% remove files in which fixation was broken
if isfield(parsed,'contrastVal')
   parsed.contrast = parsed.contrastVal;
end
parsed = structfun(@(x) x(~parsed.trialIdx & ~isnan(parsed.trialIdx)),parsed,'UniformOutput',0);

% extract values for tested eccentricities and spatial frequencies
data.nCue = 2;
data.eccVal = unique(parsed.ecc);
data.sfVal = unique(parsed.sfs);

% if computing d-prime, transform tilts and responses to present (CW; 1) and absent (CCW; 0) accordingly
if opt.use_dprime
   % transform tilts and responses to target present (CW; 1) and target absent (CCW; 0)
   parsed.tilt(parsed.tilt==-1) = 0;
   parsed.response(parsed.response==1) = 0;
   parsed.response(parsed.response==2) = 1;
end


%% Compute performance
for e = 1:numel(data.eccVal)
   for s = 1:numel(data.sfVal)
      % indices for the trials belonging to this condition
      if opt.removeCeiling
         % remove trials at 100% contrast
         trialIdx = parsed.ecc==data.eccVal(e) & parsed.sfs==data.sfVal(s) & parsed.contrast<1;
      else
         trialIdx = parsed.ecc==data.eccVal(e) & parsed.sfs==data.sfVal(s);
      end

      % create condition structures for condParser
      % contrast
      contrast.val = parsed.contrast(trialIdx);
      contrast.label = cellfun(@(x) num2str(x),num2cell(unique(contrast.val)),'UniformOutput',0);

      % cue
      cues.val = parsed.cues(trialIdx);
      cues.label = {'neutral' 'valid'};

      if opt.use_dprime
         % compute d-prime
         target.val = parsed.tilt(trialIdx);
         target.label = {'absent' 'present'};

         tmp = condParser(parsed.response(trialIdx),target,cues,contrast,bootOpt);

         % Hautas, 1995 approach
         % add 0.5 to the # of hits and # of false alarms; add 1 to the # of signal and noise trials
         % take proportion and then compute d-prime
         fa_hits = cellfun(@sum, tmp.raw)+0.5;
         noise_sig = cellfun(@numel, tmp.raw)+1;
         tmp.perf = fa_hits./noise_sig;

         % compute Hautas d-prime
         tmp.perf = squeeze(diff(norminv(tmp.perf),[],1));
         performance = tmp;

         % get # of trials per contrast level
         ntrials = squeeze(sum(cellfun(@length,tmp.raw),1));

         % fitting the naka-rushton function does not require the # of correct trials so setting this to nan
         ncorr = nan;
         
         % generate bootstrap samples
         if opt.bootstrapSamples>0
            boot_fa_hits = cellfun(@(x,y) x*numel(y)+0.5,tmp.bootstrap,tmp.raw,'UniformOutput',0);
            boot_dprime = cellfun(@(x,y) x./(numel(y)+1),boot_fa_hits,tmp.raw,'UniformOutput',0);
            boot_dprime = cellfun(@(x,y) norminv(y)-norminv(x),squeeze(boot_dprime(1,:,:,:)),squeeze(boot_dprime(2,:,:,:)),'UniformOutput',0);
            performance.bootstrap = boot_dprime;
         end
      else
         % compute proportion correct
         performance = condParser(parsed.accuracy(trialIdx),cues,contrast,bootOpt);

         % get # of trials per contrast level
         ntrials = cellfun(@length,performance.raw);

         % get # of correct trials
         ncorr = cellfun(@sum,performance.raw);
      end

      % store important variables for fitting
      % performance
      data.performance{s,e} = performance.perf;
      % contrasts
      switch opt.crfShape
         case 'logistic'
            data.contrasts{s,e} = log10(unique(contrast.val));
         case 'nakarushton'
            data.contrasts{s,e} = unique(contrast.val);
      end
      % # trials
      data.ntrials{s,e} = ntrials;
      % # correct trials
      data.ncorr{s,e} = ncorr;
      % bootstrap samples
      if opt.bootstrapSamples>0
         data.bootstrap{s,e} = performance.bootstrap;
      end
   end
end
data.nObservations = sum(cellfun(@(x) numel(x),data.performance(:)));
data.nContrastLevels = cellfun(@numel,data.contrasts);


%% Save data because loading and parsing takes too long
if ~exist(saveDir,'dir')
   mkdir(saveDir);
end
save([saveDir,filename],'data');
fprintf('Saved performance: %s\n',[saveDir,filename]);
