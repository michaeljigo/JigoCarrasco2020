%% UPDATE HELP LATER!!!!!!!!!!!!!!!!
%
% usage:    runTask(subj,eyetracking,prac_maskCheck)
% by:       Michael Jigo
% date:     07/01/18
% purpose:  Run CSF task with the parameters returned by initParams
%           (see initParams.m for more info)
%
% INPUTS:
% subj            string containing subject identifier
%
% eyetracking     eyetracking on/off (default=1)
%
% prac_maskCheck  practice block (1) (default=0)

function runTask(subj,session,verifyThresh,eyetracking,distractorType)
clear global stimulus
global stimulus

%% Defaults
if ~exist('eyetracking','var')
   eyetracking = 1;
end

if ~exist('distractorType','var')
   distractorType = 0; % 0=homogenous; 1=heterogenous
end
if distractorType
    distString = 'hetero';
else
    distString = 'homo';
end
stimulus.distractorType = distractorType;

%% Initialize parameters for main task
[stimulus.taskParams, stimulus.stimParams, stimulus.eyeParams] = initParams(subj,session,verifyThresh);

%% Initialize myscreen variable
myscreen.subj = subj;
myscreen.keyboard.nums = [124 125]; % [<- ->] arrow keys
myscreen.displayName = 'viewsonic';
myscreen.autoCloseScreen = 0;
myscreen.background = [0.5 0.5 0.5];
myscreen.saveData = -2;
if session
    myscreen.datadir = ['../data/',subj,'/',distString,'/'];
else
    myscreen.datadir = ['../data/',subj,'/threshold/'];
    if verifyThresh
       myscreen.datadir = [myscreen.datadir,'verifyThresh/'];
    end
end

% create save directory if undefined
if ~exist(myscreen.datadir,'dir')
   mkdir(myscreen.datadir);
end

% set eyelink parameters
if eyetracking
   load('./eyelinkParams.mat');
   myscreen.eyelinkParams = eyelinkParams;
end

% change mglScreenParams file to set correct distance for experiment
tmp = load('~/.mglScreenParams.mat');
possibleDisplays = cellfun(@(x) x.displayName,tmp.screenParams,'UniformOutput',0);
currentDisplay = ismember(possibleDisplays,myscreen.displayName);
tmp.screenParams{currentDisplay}.displayDistance = 115;
screenParams = tmp.screenParams;
save('~/.mglScreenParams.mat','screenParams'); clear screenParams tmp

% initialize screen
myscreen = initScreen(myscreen);

% initialize stimulus variable within myscreen
myscreen = initStimulus('stimulus',myscreen);

% enlarge text
mglTextSet([],40,[1 1 1]);

% load thresholds estimated from thresholding session
if session
    load(['../data/',subj,'/threshold/threshEstimate.mat']);
    stimulus.thresh = thresh; clear thresh
end

%% Run blocks
fprintf('nBlocks = %i\n',stimulus.taskParams.nBlocks);
for b = 1:stimulus.taskParams.nBlocks
   % set-up eyetracking
   if eyetracking
      myscreen = eyeCalibDisp(myscreen,...
         sprintf('%i/%i complete.\n Press SPACEBAR to calibrate or ENTER when ready.',b-1,stimulus.taskParams.nBlocks));
   else
      mglTextDraw(sprintf('When ready, press ENTER.'),[0 0]);
      mglFlush;
      while ~mglGetKeys(37)
         mglWaitSecs(0.1);
      end
   end

   if session
      % reset random number generator when the order of condition presentation needs to be re-shuffled
      stream = RandStream('mt19937ar','seed',sum(100*clock));
      RandStream.setDefaultStream(stream);
   
      % create fake parameter variable
      stimulus.taskParams.dummyParam = 1:5e2;

      % load file specifying # of trials subject has completed
      if exist([myscreen.datadir,'trialsCompleted_',distString,'.mat'],'file')
         load([myscreen.datadir,'trialsCompleted_',distString,'.mat']);
         stimulus.trialsCompleted = trialsCompleted; clear trialsCompleted;
         stimulus.currentParamOrder = currentParamOrder; clear currentParamOrder;
         stimulus.allTrialsCompleted = allTrialsCompleted; clear allTrialsCompleted
      else
         stimulus.trialsCompleted = 0;
         stimulus.allTrialsCompleted = 0;
      end
   
      % run CRF task
      distractTask(myscreen);
   
      % save the # of trials that were completed in the current block and the current parameter order
      allTrialsCompleted = stimulus.allTrialsCompleted;
      trialsCompleted = stimulus.trialsCompleted;
      currentParamOrder = stimulus.currentParamOrder;
      save([myscreen.datadir,'trialsCompleted_',distString,'.mat'],'trialsCompleted','currentParamOrder','allTrialsCompleted')
   else
      if stimulus.taskParams.verifyThresh
          load(['../data/',subj,'/threshold/threshEstimate.mat']);
          for e = 1:size(thresh,2)
              for f = 1:size(thresh,1)
                  stimulus.taskParams.psiM(e,f).xCurrent = thresh(f,e);
              end
          end
          stimulus.thresh = thresh;
      end
      
      % thresholding session
      threshSess(myscreen);

      if stimulus.taskParams.verifyThresh
         % compute performance on that block for each ecc x SF
         for e = 1:size(stimulus.taskParams.psiM,1)
            for f = 1:size(stimulus.taskParams.psiM,2)
              condIdx = stimulus.sfs==stimulus.taskParams.sfs(f) & stimulus.ecc==stimulus.taskParams.ecc(e) & ~stimulus.brokenTrial.trialIdx;
              block_ncorr(b,e,f) = sum(stimulus.accuracy(condIdx));
              block_ntrials(b,e,f) = sum(condIdx);
            end
         end
        
         % adjust thresholds every 24 trials per condition
         if all(nansum(block_ntrials,1)>=24)
            load(['../data/',subj,'/threshold/threshEstimate.mat']);
            orgThresh = thresh;
            
            blockPerf = squeeze(nansum(block_ncorr,1))./squeeze(nansum(block_ntrials,1));
            % compute difference from 75% for each condition
            blockPerf = (0.75-blockPerf)*100; % negative values=better performance; positive values=worse performance

            % change contrast based on difference from 75% correct (0.01 log units/1% performance difference)
            contrastChange = blockPerf*0.01;
            thresh = thresh+contrastChange';
            save(['../data/',subj,'/threshold/threshEstimate.mat'],'thresh');
            
            % update xCurrent values with updated thresholds
            for e = 1:size(stimulus.taskParams.psiM,1)
                for f = 1:size(stimulus.taskParams.psiM,2)
                    stimulus.taskParams.psiM(e,f).xCurrent = thresh(f,e);
                end
            end
           
            block_ntrials(1:b,:,:) = nan;
            block_ncorr(1:b,:,:) = nan;
         end 

      end
   end
end
mglTextDraw('Session completed. Please exit the room.',[0 0]);
mglFlush;
mglWaitSecs(5);
mglClose;
