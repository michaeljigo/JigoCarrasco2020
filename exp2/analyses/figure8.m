% Purpose:  Recreate Figure 8. 
%           Contrast Sensitivity Functions and performance in the Neutral condition across the group in Experiment 2.
%
% By:       Michael Jigo
% Edited:   06.29.21
%

function figure8
addpath(genpath('./helperFun'));

attention_type = {'exo' 'endo'};

%% compute group-average data
   % get data
   [alldata params] = pack_experiment_results;

   for a = 1:numel(attention_type)
      switch attention_type{a}
         case 'exo'
            data = alldata(1);
         case 'endo'
            data = alldata(2);
      end

      % compute group-averages and SEM
         % contrast sensitivity
         cs                      = 1./permute(data.thresh,[1 4 3 2]);
         group.avg.cs(:,:,a)     = squeeze(mean(cs,1));
         group.err.cs(:,:,a)     = squeeze(std(cs)./sqrt(size(data.thresh,1)));
      
         % performance
         group.avg.dprime(:,:,a) = squeeze(mean(data.performance(:,1,:,:),1))';
         group.err.dprime(:,:,a) = squeeze(std(data.performance(:,1,:,:))./sqrt(size(data.thresh,1)))';
         
      
   %% fit double-expponential function to group-average contrast sensitivity
      for e = 1:size(group.avg.cs,1)
         group.avg.csfparams(e,:,a) = fit_dexp2csf(data.freq,group.avg.cs(e,:,a)'); 
      end
   end


%% plot fit to group CSF
   figure('Name',sprintf('Group-average CSF + Performance')); 
   colors   = [0 0 0; 150 150 150]./255;
   fitSF    = logspace(log10(0.25),log10(32),1e3);
   subplots = [1 2];

   for a = 1:numel(attention_type)
      for e = 1:numel(data.ecc)
         subplot(2,2,subplots(a));
         % evaluate double-exponential fit to CSF
            fitCS = evalCSF('dexp',fitSF,squeeze(group.avg.csfparams(e,:,a)));

         % plot fits
            leg(e) = loglog(fitSF,fitCS,'-','Linewidth',3,'color',colors(e,:)); hold on

         % plot raw data
            errorbar(data.freq,squeeze(group.avg.cs(e,:,a)),squeeze(group.err.cs(e,:,a)),'Linestyle','none','Color',colors(e,:),'Linewidth',2,'CapSize',0); hold on
            loglog(data.freq,squeeze(group.avg.cs(e,:,a)),'o','MarkerSize',5,'color','w'); hold on
            loglog(data.freq,squeeze(group.avg.cs(e,:,a)),'o','MarkerSize',4,'markerfacecolor',colors(e,:),'markeredgecolor','none'); hold on
      end
      % pretty up figure
         figureDefaults
         set(gca,'xlim',[0.4 20],'xtick',[0.5 1 2 4 8 16],'xticklabel',{'0.5' '1' '2' '4' '8' '16'},'ylim',[0.8 200],'ytick',[1 10 100 200 300],...
            'ticklength',[0.025 0.05]);
         ylabel('Contrast sensitivity (c^{-1})','fontname','arial','fontsize',10);
         legend(leg,cellfun(@num2str,num2cell(data.ecc),'uniformoutput',0),'location','southwest');
         title(sprintf('%s',upper(attention_type{a})),'fontname','arial','fontsize',8);
   end

   
%% plot group-average performance
   subplots = [3 4];

   for a = 1:numel(attention_type)
      for e = 1:numel(data.ecc)
         subplot(2,2,subplots(a));
         % plot raw data
            errorbar(data.freq,squeeze(group.avg.dprime(e,:,a)),squeeze(group.err.dprime(e,:,a)),'Linestyle','none','Color',colors(e,:),'Linewidth',2,'CapSize',0); hold on
            semilogx(data.freq,squeeze(group.avg.dprime(e,:,a)),'o','MarkerSize',6,'color','w'); 
            loglog(data.freq,squeeze(group.avg.dprime(e,:,a)),'o','MarkerSize',5,'markerfacecolor',colors(e,:),'markeredgecolor','none'); 
      end
      % pretty up figure
         figureDefaults
         set(gca,'xlim',[0.4 20],'xtick',[0.5 1 2 4 8 16],'xticklabel',{'0.5' '1' '2' '4' '8' '16'},'ylim',[0 2],'ytick',0:3,...
            'ticklength',[0.025 0.05],'xscale','log');
         xlabel('Spatial frequency (cpd)','fontname','arial','fontsize',10); ylabel('Performance (d^{\prime})','fontname','arial','fontsize',10);
         legend(leg,cellfun(@num2str,num2cell(data.ecc),'uniformoutput',0),'location','southwest');
   end
