% Purpose:  Wrapper function to fit SF profiles (symmetric and uniform) to exogenous and endogenous attention datasets.
%
% By:       Michael Jigo
% Edited:   06.23.21

function fit_all_subj

subjList = {'AS' 'DT' 'KT' 'MJ' 'MM' 'RF' 'SO' 'SP' 'SX' 'YS'};

for s = 1:numel(subjList)
   % attention effects
      fit_subjFullModel(subjList{s},'endo','use_dprime',1,'attnShape','uniform','attnModelNum',1,'dispFig',0,'overwriteFit',1);
      fit_subjFullModel(subjList{s},'endo','use_dprime',1,'attnShape','symmetric','attnModelNum',1,'dispFig',0,'overwriteFit',1);
      fit_subjFullModel(subjList{s},'exo','use_dprime',1,'attnShape','uniform','attnModelNum',1,'dispFig',0,'overwriteFit',1);
      fit_subjFullModel(subjList{s},'exo','use_dprime',1,'attnShape','symmetric','attnModelNum',1,'dispFig',0,'overwriteFit',1);

   % contrast sensitivity function
      fit_subjCSF(subjList{s},'exo');
      fit_subjCSF(subjList{s},'endo');
end
