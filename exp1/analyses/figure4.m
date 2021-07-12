% Purpose:  Recreate Figure 4. 
%           Contrast Sensitivity Functions across the group in Experiment 1.
%
% By:       Michael Jigo
% Edited:   06.22.21
%
% Input:    attention_type    'exo' or 'endo'

function figure4(attention_type)
addpath(genpath('./helperFun'));

%% compute group-average data
   % get data
   [data params] = pack_experiment_results;

   switch attention_type
      case 'exo'
         data = data(1);
      case 'endo'
         data = data(2);
   end

   % compute group-averages and SEM
      % contrast sensitivity
      cs                = 1./permute(data.crf.thresh,[1 4 3 2]);
      group.avg.cs      = squeeze(mean(cs,1));
      group.err.cs      = squeeze(std(cs)./sqrt(size(data.crf.thresh,1)));

      % maximum contrast sensitivity parameter
      group.avg.maxCS   = mean(data.csf.maxCS,1);
      group.err.maxCS   = std(data.csf.maxCS,[],1)./sqrt(size(data.csf.maxCS,1));
      
      % peak SF
      group.avg.peakSF  = mean(data.csf.peakSF,1);
      group.err.peakSF  = std(data.csf.peakSF,[],1)./sqrt(size(data.csf.peakSF,1));


%% Fit double-exponential function to group-average data
   csfInit              = initCSFModel('dexp');
   group.avg.csfparams  = fitCSFModel(group.avg.cs,csfInit);

   
%% Plot fit to group CSF   
   figure('Name',sprintf('Group-average CSF: %s',upper(attention_type)),'position',[680 699 437 249]); 
   colors   = [0 0 0; 82 82 82; 150 150 150; 204 204 204]./255;
   fitSF    = logspace(log10(0.25),log10(32),1e3);
   subplot(2,2,[1 3]);

for e = 1:numel(data.ecc)
   % evaluate double-exponential fit to CSF
      fitCS = evalCSF('dexp',fitSF,squeeze(group.avg.csfparams(1,e,:)));

   % plot fits
      leg(e) = loglog(fitSF,fitCS,'-','Linewidth',3,'color',colors(e,:)); hold on

   % plot raw data
      loglog(data.freq,squeeze(group.avg.cs(1,:,e)),'o','MarkerSize',5,'color','w'); hold on
      loglog(data.freq,squeeze(group.avg.cs(1,:,e)),'o','MarkerSize',4,'markerfacecolor',colors(e,:),'markeredgecolor','none'); hold on
      errorbar(data.freq,squeeze(group.avg.cs(1,:,e)),squeeze(group.err.cs(1,:,e)),'Linestyle','none','Color',colors(e,:),'Linewidth',2,'CapSize',0);
end
% pretty up figure
   figureDefaults
   set(gca,'xlim',[0.4 20],'xtick',[0.5 1 2 4 8 16],'xticklabel',{'0.5' '1' '2' '4' '8' '16'},'ylim',[0.8 200],'ytick',[1 10 100 200 300],...
      'ticklength',[0.025 0.05]);
   xlabel('Spatial frequency (cpd)','fontname','arial','fontsize',10); ylabel('Contrast sensitivity (c^{-1})','fontname','arial','fontsize',10);
   legend(leg,cellfun(@num2str,num2cell(data.ecc),'uniformoutput',0),'location','southwest');


%% Add group-average parameters
   % maximum CS
      subplot(2,2,2)
      semilogy(data.ecc,group.avg.maxCS,'o','markersize',5,'color','w'); hold on
      semilogy(data.ecc,group.avg.maxCS,'o','markersize',4,'markerfacecolor','k','markeredgecolor','none'); 
      errorbar(data.ecc,group.avg.maxCS,group.err.maxCS,'linestyle','none','color','k','capsize',0);
      figureDefaults
      set(gca,'xlim',[-1 13],'xtick',0:3:12,'ylim',[40 150],'ytick',[50 100 150],'ticklength',[0.025 0.05]);
      xlabel('Eccentricity','fontname','arial','fontsize',10); 
      ylabel('\gamma_{csf} (c^{-1})','fontname','arial','fontsize',10);
   
   % peak SF
      subplot(2,2,4)
      semilogy(data.ecc,group.avg.peakSF,'o','markersize',5,'color','w'); hold on
      semilogy(data.ecc,group.avg.peakSF,'o','markersize',4,'markerfacecolor','k','markeredgecolor','none'); 
      errorbar(data.ecc,group.avg.peakSF,group.err.peakSF,'linestyle','none','color','k','capsize',0);
      figureDefaults
      set(gca,'xlim',[-1 13],'xtick',0:3:12,'ylim',[1 3],'ytick',[1 2 3],'ticklength',[0.025 0.05]);
      xlabel('Eccentricity','fontname','arial','fontsize',10); 
      ylabel('f_{csf} (cpd)','fontname','arial','fontsize',10);
