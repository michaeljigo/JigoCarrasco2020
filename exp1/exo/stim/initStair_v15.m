% UPDATE LATER!!!!!!!!!!!!!!!!
%
%
% Initialize or load staircases for a subject, given their initials, tested SFs, 
% eccentricities, and number of thresholds.
% taskParams will be other input (includes nSF, nEcc,nThresh,nLoc,nTrials)
% usage:    initStair(subj,taskParams,stairParams,emptyStair)
% by:       Michael Jigo
% date:     07/01/18
% purpose:  Initialize staircase for use in CSF experiment.
%
% INPUTS
% subj         string containing identifier for subject
%
% taskParams   see initParams for more info
%
% stairParams  see initParams for more info
%
% emptyStair   concatenate an empty staircase when a new threshold repetition is
%              initialized (1) or do nothing
%
% OUTPUTS
% stair        see nDown1Up.m for more info
%
% stairInfo
%     stairParams       staircase-related parameters used to initialize struct
%     taskParams        task-related parameters used to initialize staircase struct
%     subj              subject identifier
%     dimensions        identity of each dimension in staircase structure array
%     threshCollected   # of thresholds obtained for subject
%  
function [stair, stairInfo] = initStair(subj,taskParams,stairParams)

dataDir = ['../data/',subj,'/threshold/'];
if exist([dataDir,'stair.mat'],'file')
   load([dataDir,'stair.mat']);
   return
end

%% Initialize staircase
for s = 1:length(taskParams.sfs)
   for l = 1:length(taskParams.loc)
      for e = 1:length(taskParams.ecc)
         % initialize staircase structure
         init = nDown1Up(stairParams);
         % store staircase
         stair(1,s,l,e) = init;
      end
   end
end

%% Add bookkeeping info
stairInfo.stairParams = stairParams;
stairInfo.taskParams = taskParams;
stairInfo.subj = subj;
stairInfo.dimensions = {'cues' 'sfs' 'loc' 'ecc'};
stairInfo.threshCollected = 0;
