% Purpose:  Recreate Figure 3. 
%           Contrast Response Functions from representative observers in Experiment 1.
%
% By:       Michael Jigo
% Edited:   06.22.21
%
% Input:    attention_type    'exo' or 'endo'

function figure3(attention_type)
addpath(genpath('./helperFun'));

%% load best-fitting parameters for representative subjects
   switch attention_type
      case 'exo'
         subj     = 'MJ';
         ecc      = 3;
         profile  = 'symmetric';
         colors   = [0 0 0; 5 113 176]./255;
      case 'endo'
         subj     = 'LH';
         ecc      = 12;
         profile  = 'uniform';
         colors   = [0 0 0; 202 0 32]./255;
   end
   datadir        = sprintf('../%s/data/%s/fullModel/',attention_type,subj);
   load(sprintf('%sfitParameters_dexp_nakarushton5_%s1_dprime.mat',datadir,profile));

   % get the eccentricity index for this observer
      eccidx         = find(ismember(data.eccVal,ecc));


%% Display CRFs
   figure('Name',sprintf('%s - %i deg',upper(attention_type),data.eccVal(eccidx)),'position',[3 685 1257 263]);
  
   % plotting parameters
      sizePerTrial   = 0.125;
      fitContrast    = logspace(log10(1e-4),log10(0.3),1e3);
   
   % extract thresholds for each condition
      [thresh75 threshMid crf attn] = extract_thresholds(data,csf,attn,crf);
   
   % only show 0.5-4 cpd
      for s = 1:4
         subplot(1,4,s);
         
         % in lieu of a break, map 100% contrast to 30% contrast
            contrastLevels = data.contrasts{s,eccidx};
            contrastLevels(contrastLevels==1) = 0.3;

         % plot CRFs for each cueing condition
            for c = 1:data.nCue
               % plot CRF fit
                  % evaluate fit
                     crfParams = [threshMid(eccidx,s,c) crf.slope(eccidx,s,c) 0 crf.upperAsymptote(eccidx,s,c)];
                     fitCRF = evalPF(crf.name,fitContrast,crfParams);
                  
                  % draw line for threshold corresponding to 75% correct
                     line([thresh75(eccidx,s,c) thresh75(eccidx,s,c)],[0 evalPF(crf.name,thresh75(eccidx,s,c),crfParams)],...
                        'Color',colors(c,:),'Linewidth',2); hold on

                  % draw fit
                     semilogx(fitContrast,fitCRF,'-','Color',colors(c,:),'Linewidth',3);
               
                     
                  % plot raw data
                  for p = 1:numel(contrastLevels)
                     semilogx(contrastLevels(p),data.performance{s,eccidx}(c,p),'o','MarkerSize',sizePerTrial*data.ntrials{s,eccidx}(c,p),...
                     'markerfacecolor',colors(c,:),'markeredgecolor',[1 1 1]); 
                  end
            

            end
         
            % pretty up figure
               figureDefaults;
               title(sprintf('%.1f cpd',data.sfVal(s)),'fontname','arial','fontsize',10);
               set(gca,'XLim',[0.002 max(contrastLevels)],'XTick',[0.01 0.1 0.2 0.3],'YLim',[0 5],'YTick',0:1:6,...
                  'xticklabel',{'0.01' '0.1' '0.2' '1'},'ticklength',[0.025 0.05],'xscale','log');
               if s==1
                  xlabel('Contrast (%)','fontname','arial','fontsize',10); ylabel('Performance','fontname','arial','fontsize',10);
               end
         end
