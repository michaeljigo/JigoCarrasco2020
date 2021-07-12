% Purpose:  This function will take the names and values of optional inputs and create an "opt" structure containing them. 
% By:       Michael Jigo

function opt = parseOptionalInputs(names,val,updateVals)

% if updateVals is a cell array, that means that varargin was used as input in a nested function. expand cell array
if numel(updateVals)==1 && iscell(updateVals)
   updateVals = updateVals{1};
end

% check for length between default names and values
if ~isequal(numel(names),numel(val))
   error('WHOOPS! Mismatch in number of names annd number of default values.')
end

% align actual inputs with the possible inputs
[~,optIdx] = ismember(names,updateVals(1:2:end));
[~,userIdx] = ismember(updateVals(1:2:end),names);

% remove names (in updateVals) that are not part of the defaults specified in "names"
invalidIn = find(userIdx==0)*2;
updateVals([invalidIn invalidIn-1]) = [];
userIdx(userIdx==0) = [];

if isempty(userIdx)
   % if none of the to-be-updated values are not included, just set the defaults
   for i = 1:length(names)
      opt.(names{i}) = val{i};
   end
else
   % if some relevant parameters are inputted, update the corresponding values
   userIn = cell(1,length(names)); userIn(userIdx) = updateVals(2:2:end);
   userIn(optIdx==0) = val(optIdx==0);

   % create the input variables
   for i = 1:length(names)
      opt.(names{i}) = userIn{i};
   end
end
