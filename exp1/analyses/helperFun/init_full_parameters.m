% Purpose:  Initialize the set of parameters that will be used to model the CSF, attention modulation, and CRF. 
%           CRF and attention modulations will have a different number of models representing different subsets of parameters being fixed or free across conditions (Cue, SF, or Eccentricity).

function [csf attn crf] = init_full_parameters(data,opt)

%% CSF parameters
switch opt.csfShape
   case 'dexp'
      paramNames = {'slope' 'peakSF' 'amplitude'};
      paramBnds = {[1 3] [0.7071 8] [1 300]};
   case 'logparab'
      paramNames = {'peakSF' 'bandwidth' 'amplitude'};
      paramBnds = {[0.5 8] [0.5 2] [1 500]};
   otherwise
      error('%s not implemented.',opt.csfShape);
end

% create csf structure containing randomly chosen initial values for each parameter
csf.name = opt.csfShape;
for name = 1:numel(paramNames)
   csf.bnd.(paramNames{name}) = transpose(ones(numel(data.eccVal),2).*paramBnds{name});
   csf.(paramNames{name}) = rand(1,numel(data.eccVal))*diff(paramBnds{name})+min(paramBnds{name});
end


%% Attention modulation parameters
switch opt.attnShape
   case 'symmetric'
      paramNames = {'center' 'lowSlope' 'amplitude' 'exponent'};
      paramBnds = {log2([0.7071 8]) [1 3] [-1 1] [2 2]};
   case 'uniform'
      paramNames = {'center' 'lowSlope' 'amplitude' 'exponent'};
      paramBnds = {log2([0.7071 8]) [0.5 4] [0 1] [10 10]};
   otherwise
      error('%s not implemented.',opt.attnShape);
end

% create attn structure containing randomly chosen initial values
attn.name = opt.attnShape;
for name = 1:numel(paramNames)
   attn.bnd.(paramNames{name}) = transpose(ones(numel(data.eccVal),2).*paramBnds{name});
   attn.(paramNames{name}) = rand(1,numel(data.eccVal))*diff(paramBnds{name})+min(paramBnds{name});
end

% remove values to signify that certain parameters are fixed across eccentricity
switch opt.attnModelNum
   case 1
      % do nothing, all parameters are free to vary
   case 2
      % center is fixed across eccentricity
      attn.center = attn.center(1);
      attn.bnd.center = attn.bnd.center(:,1);
   case 3
      % amplitude is fixed across eccentricity
      attn.amplitude = attn.amplitude(1);
      attn.bnd.amplitude = attn.bnd.amplitude(:,1);
   case 4
      % spread is fixed across eccentricity
      nSpreadParams = find(cellfun(@(x) ~isempty(strfind(lower(x),'slope')),paramNames));
      for n = 1:numel(nSpreadParams)
         attn.(paramNames{nSpreadParams(n)}) = attn.(paramNames{nSpreadParams(n)})(1);
         attn.bnd.(paramNames{nSpreadParams(n)}) = attn.bnd.(paramNames{nSpreadParams(n)})(:,1);
      end
   case 5
      % center and amplitude are fixed across eccentricity
      attn.center = attn.center(1);
      attn.amplitude = attn.amplitude(1);
      attn.bnd.center = attn.bnd.center(:,1);
      attn.bnd.amplitude = attn.bnd.amplitude(:,1);
   case 6
      % center and spread are fixed across eccentricity
      attn.center = attn.center(1);
      attn.bnd.center = attn.bnd.center(:,1);
      nSpreadParams = find(cellfun(@(x) ~isempty(strfind(lower(x),'slope')),paramNames));
      for n = 1:numel(nSpreadParams)
         attn.(paramNames{nSpreadParams(n)}) = attn.(paramNames{nSpreadParams(n)})(1);
         attn.bnd.(paramNames{nSpreadParams(n)}) = attn.bnd.(paramNames{nSpreadParams(n)})(:,1);
      end
   case 7
      % amplitude and spread are fixed across eccentricity
      attn.amplitude = attn.amplitude(1);
      attn.bnd.amplitude = attn.bnd.amplitude(:,1);
      nSpreadParams = find(cellfun(@(x) ~isempty(strfind(lower(x),'slope')),paramNames));
      for n = 1:numel(nSpreadParams)
         attn.(paramNames{nSpreadParams(n)}) = attn.(paramNames{nSpreadParams(n)})(1);
         attn.bnd.(paramNames{nSpreadParams(n)}) = attn.bnd.(paramNames{nSpreadParams(n)})(:,1);
      end
   case 8
      % center, amplitude, and spread are fixed across eccentricity 
      attn.center = attn.center(1);
      attn.amplitude = attn.amplitude(1);
      attn.bnd.center = attn.bnd.center(:,1);
      attn.bnd.amplitude = attn.bnd.amplitude(:,1);
      nSpreadParams = find(cellfun(@(x) ~isempty(strfind(lower(x),'slope')),paramNames));
      for n = 1:numel(nSpreadParams)
         attn.(paramNames{nSpreadParams(n)}) = attn.(paramNames{nSpreadParams(n)})(1);
         attn.bnd.(paramNames{nSpreadParams(n)}) = attn.bnd.(paramNames{nSpreadParams(n)})(:,1);
      end
end
if ~strcmp(opt.attnShape,'scalar')
   % exponent parameter is always fixed across eccentricity
   attn.exponent = attn.exponent(1);
   attn.bnd.exponent = attn.bnd.exponent(:,1);
end


%% CRF parameters
switch opt.crfShape
   case 'logistic'
      paramNames = {'slope' 'upperAsymptote'};
      paramBnds = {[1 20] [0 0.5]};
   case 'nakarushton'
      paramNames = {'slope' 'upperAsymptote'};
      paramBnds = {[1 6] [0 5]};
   otherwise
      error('%s not implemented.',opt.crfShape);
end

% create crf structure containing randomly chosen initial values
crf.name = opt.crfShape;
for name = 1:numel(paramNames)
   crf.bnd.(paramNames{name}) = permute(repmat(shiftdim(paramBnds{name},-2),[numel(data.eccVal) numel(data.sfVal) data.nCue 1]),[4 1 2 3]);
   crf.(paramNames{name}) = rand(numel(data.eccVal),numel(data.sfVal),data.nCue)*diff(paramBnds{name})+min(paramBnds{name});
end
% store full matrix size
crf.fullMatrixSize = size(crf.slope);


switch opt.crfModelNum
   case 1
      % do nothing, all parameters are free to vary
   case 2
      % slope fixed across cues
      crf.slope = crf.slope(:,:,1);
      crf.bnd.slope = crf.bnd.slope(:,:,:,1);
   case 3
      % upper asymptote fixed across cues
      crf.upperAsymptote = crf.upperAsymptote(:,:,1);
      crf.bnd.upperAsymptote = crf.bnd.upperAsymptote(:,:,:,1);
   case 4
      % slope fixed across cues and eccentricity
      crf.slope = crf.slope(1,:,1);
      crf.bnd.slope = crf.bnd.slope(:,1,:,1);
   case 5
      % slope fixed across SF and cues
      crf.slope = crf.slope(:,1,1);
      crf.bnd.slope = crf.bnd.slope(:,:,1,1);
   case 6
      % slope fixed across eccentricity, SF, and cues
      crf.slope = crf.slope(1,1,1);
      crf.bnd.slope = crf.bnd.slope(:,1,1,1);
   case 7
      % slope and upper asymptote fixed across cues
      crf.slope = crf.slope(:,:,1);
      crf.upperAsymptote = crf.upperAsymptote(:,:,1);
      crf.bnd.slope = crf.bnd.slope(:,:,:,1);
      crf.bnd.upperAsymptote = crf.bnd.upperAsymptote(:,:,:,1);
   case 8
      % slope fixed across cues and eccentricity; upper asymptote fixed across cues
      crf.slope = crf.slope(1,:,1);
      crf.bnd.slope = crf.bnd.slope(:,1,:,1);
      crf.upperAsymptote = crf.upperAsymptote(:,:,1);
      crf.bnd.upperAsymptote = crf.bnd.upperAsymptote(:,:,:,1);
   case 9
      % slope fixed across SF and cues; upper asymptote fixed across cues
      crf.slope = crf.slope(:,1,1);
      crf.upperAsymptote = crf.upperAsymptote(:,:,1);
      crf.bnd.slope = crf.bnd.slope(:,:,1,1);
      crf.bnd.upperAsymptote = crf.bnd.upperAsymptote(:,:,:,1);
   case 10
      % slope fixed across eccentricity, SF, and cues; upper asymptote fixed across cues
      crf.slope = crf.slope(1,1,1);
      crf.upperAsymptote = crf.upperAsymptote(:,:,1);
      crf.bnd.slope = crf.bnd.slope(:,1,1,1);
      crf.bnd.upperAsymptote = crf.bnd.upperAsymptote(:,:,:,1);
end
