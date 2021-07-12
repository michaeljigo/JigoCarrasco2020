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
function [stair, stairInfo] = initStair_stairHL(subj,taskParams,stairParams,emptyStair)

if ~exist('emptyStair','var'), emptyStair = 0; end
%% Load or initialize staircase
% If subject folder is present and staircases have been initialized, load them
dataDir = ['../data/',subj,'/'];
if exist([dataDir,'stair.mat'],'file') && ~emptyStair
   load([dataDir,'stair.mat']);

   % Check if the correct observer was loaded
   if ~strcmp(subj,stairInfo.subj)
      error('Wrong observer loaded. Please check staircase file.');
   end

   % Check if the sfs, ecc, and locations in the data file match the task parameters
   if ~all(ismember(taskParams.sfs,stairInfo.taskParams.sfs))
      error('Spatial frequencies do not match. Make sure that the correct parameters were used to initialize the staircases.');
   end

   if ~all(ismember(taskParams.ecc,stairInfo.taskParams.ecc))
      error('Eccentricities do not match. Make sure that the correct parameters were used to initialize the staircases.');
   end

   if ~isequal(stairParams.nTrials,stairInfo.stairParams.nTrials)
      error('# of trials do not match. Make sure that the correct parameters were used to initialize the staircases.');
   end

   if ~isequal(taskParams.cues,stairInfo.taskParams.cues)
      error('# of cues do not match. Make sure that the correct parameters were used to initialize the staircases.');
   end

   if ~isequal(taskParams.loc,stairInfo.taskParams.loc)
      error('# of locations do not match. Make sure that the correct parameters were used to initialize the staircases.');
   end

else
   % Initialize staircases
   for c = 1:length(taskParams.cues)
      for s = 1:length(taskParams.sfs)
         for l = 1:length(taskParams.loc)
            for e = 1:length(taskParams.ecc)
               % Select the starting level used by the staircase
               startLevel = stairParams.startLevels(stairParams.stairRep,c,s,l,e);
               thisParams = rmfield(stairParams,{'startLevels'});
               thisParams.startLevel = startLevel;

               % initialize staircase structure
               init = nDown1Up(thisParams);

               % insert tilts (equal probability for CW and CCW tilts for each stair)
               cw = ones(1,floor(stairParams.nTrials/2));
               ccw = ones(1,stairParams.nTrials-length(cw))*-1;
               tilts = [cw ccw];
               tilts = tilts(randperm(stairParams.nTrials));
               init.tilts = tilts;

               % store staircase
               stair(c,s,l,e) = init;
            end
         end
      end
   end
   %% Add bookkeeping info
   stairInfo.stairParams = stairParams;
   stairInfo.taskParams = taskParams;
   stairInfo.subj = subj;
   stairInfo.dimensions = {'cues' 'sfs' 'loc' 'ecc'};
   stairInfo.threshCollected = 0;
end
