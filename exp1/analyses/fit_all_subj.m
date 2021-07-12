% Purpose:  Wrapper function to fit SF profiles (symmetric and uniform) to exogenous and endogenous attention datasets.
%
% By:       Michael Jigo
% Edited:   06.23.21

function fit_all_subj

subjList = {'AB' 'AF' 'AS' 'LH' 'LS' 'MJ' 'RF' 'SC' 'SX'};

attn = {'exo' 'endo'};
attnShape = {'symmetric' 'uniform'};

for s = 1:numel(subjList)
   for a = 1:numel(attn)
      for as = 1:numel(attnShape)
            fit_subjFullModel(subjList{s},attn{a},'nStartPoints',10,'overwriteFit',1,'bootstrapSamples',0,'attnShape',attnShape{as},'overwritePerformance',1);
      end
   end
end
