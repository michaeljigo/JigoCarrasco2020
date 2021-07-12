% Purpose:  Initialize the set of parameters that will be used to model discriminability on the Neutral condition and Attention modulation.
%           Neutral parameter will be just a single number corresponding to the y-intercept of performance (d-prime or proportion correct).
%           Attention parameters will define a symmetric, skewed, or uniform Gaussian function.

function attn = init_full_parameters(data,opt)

%% Attention modulation parameters
switch opt.attnShape
   case 'symmetric'
     paramNames = {'center' 'lowSlope' 'amplitude' 'exponent'};
     paramBnds = {log2([0.7071 8]) [0.25 4] [0 2] [2 2]};
     %paramBnds = {log2([1.5 8]) [0.5 2] [0 2] [2 2]};
   case 'skewed'
      paramNames = {'center' 'lowSlope' 'highSlope' 'amplitude' 'exponent'};
      paramBnds = {log2([0.5 8]) [0.1 2] [0.5 2] ampBnds [2 2]};
   case 'uniform'
      paramNames = {'center' 'lowSlope' 'amplitude' 'exponent'};
     paramBnds = {log2([0.7071 8]) [1.5 4] [0 2] [10 10]};
      %paramBnds = {log2([1 8]) [1 2.5] [0 2] [10 10]};
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
% exponent parameter is always fixed across eccentricity
attn.exponent = attn.exponent(1);
attn.bnd.exponent = attn.bnd.exponent(:,1);
