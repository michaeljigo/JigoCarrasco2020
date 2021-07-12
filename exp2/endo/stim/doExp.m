% Purpose:  This is a wrapper function that will streamline the running of the attention distractor experiment.

function doExp(subj,whichSession,eyetracking)
addpath('../anal');

if ~exist('eyetracking','var')
   eyetracking = 1;
end

switch whichSession
   case 0
      % thresholding session
      runTask(subj,whichSession,eyetracking);
   case 1
      % main experiment
      runTask(subj,whichSession,eyetracking);
end