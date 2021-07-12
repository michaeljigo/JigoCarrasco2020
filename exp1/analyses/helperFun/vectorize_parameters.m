% Purpose:  If inputs are three separate structures, put all parameter values into a vector for input into optimization algorithm. 
%           If there are 4 inputs, re-structure the vector input (4th input) into the original three structures for each component of the model.

function [params_vec bnd_vec csf attn crf] = vectorize_parameters(csf,attn,crf,params_vec)

if nargin==3
   %% Vectorize parameters
   % initialize parameter vector
   params_vec = [];
   bnd_vec = [];

   % add csf parameters into vector
   fields = fieldnames(csf); fields =  fields(~ismember(fields,{'bnd' 'name'}));
   for f = 1:numel(fields)
      params_vec = [params_vec; csf.(fields{f})']; 
      bnd_vec = [bnd_vec csf.bnd.(fields{f})];
   end

   % add attention modulation parameters into vector
   fields = fieldnames(attn); fields = fields(~ismember(fields,{'bnd' 'name'}));
   for f = 1:numel(fields)
      params_vec = [params_vec; attn.(fields{f})']; 
      bnd_vec = [bnd_vec attn.bnd.(fields{f})];
   end

   % add crf parameters into vector
   fields = fieldnames(crf); fields = fields(~ismember(fields,{'bnd' 'name' 'fullMatrixSize'}));
   for f = 1:numel(fields)
      params_vec = [params_vec; crf.(fields{f})(:)]; 
      fieldBnd = [squeeze(crf.bnd.(fields{f})(1,:)); squeeze(crf.bnd.(fields{f})(2,:))];
      bnd_vec = [bnd_vec fieldBnd];
   end
   bnd_vec = bnd_vec';
elseif nargin==4
   bnd_vec = [];
   %% Re-structure parameters
   % csf 
   fields = fieldnames(csf); fields =  fields(~ismember(fields,{'bnd' 'name'}));
   for f = 1:numel(fields)
      csf.(fields{f}) = reshape(params_vec(1:numel(csf.(fields{f}))),size(csf.(fields{f})));
      % always remove values that have been re-structurized
      params_vec(1:numel(csf.(fields{f}))) = [];
   end

   % attention modulation
   fields = fieldnames(attn); fields = fields(~ismember(fields,{'bnd' 'name'}));
   for f = 1:numel(fields)
      attn.(fields{f}) = reshape(params_vec(1:numel(attn.(fields{f}))),size(attn.(fields{f})));
      params_vec(1:numel(attn.(fields{f}))) = [];
   end

   % crf
   fields = fieldnames(crf); fields = fields(~ismember(fields,{'bnd' 'name' 'fullMatrixSize'}));
   for f = 1:numel(fields)
      crf.(fields{f}) = reshape(params_vec(1:numel(crf.(fields{f}))),size(crf.(fields{f})));
      params_vec(1:numel(crf.(fields{f}))) = [];
   end
end
