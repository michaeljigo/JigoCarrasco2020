% Purpose:  Recreate Figure 6. 
%           Cueing effect across SF for exogenous and endogenous attention.
%
% By:       Michael Jigo
% Edited:   06.22.21
%
% Input:    attention_type    'exo' or 'endo'

function figure6(attention_type)
addpath(genpath('./helperFun'));

%% compute group-average data
   % get data
   [data params] = pack_experiment_results;

   switch attention_type
      case 'exo'
         data        = data(1);
         color       = [5 113 176]./255;
         attnshape   = 'symmetric'; 
      case 'endo'
         data        = data(2);
         color       = [202 0 32]./255;
         attnshape   = 'uniform'; 
   end

   % compute group-averages and SEM
      % attention effect
      group.avg.attn          = data.attn.avg_modulation;
      group.err.attn          = squeeze(std(data.attn.attn_mod)./sqrt(size(data.crf.thresh,1)));

      % Neutral peak SF
      group.avg.neut_peakSF   = mean(data.csf.peakSF,1);
      group.err.neut_peakSF   = std(data.csf.peakSF,[],1)./sqrt(size(data.csf.peakSF,1));
      
      % Attention peak SF
      group.avg.attn_peakSF   = mean(2.^data.attn.centerSF,1);
      group.err.attn_peakSF   = std(2.^data.attn.centerSF,[],1)./sqrt(size(data.csf.peakSF,1));


%% Fit group-average attention profile
   attnInit          = initHypothesis(attnshape,1);
   data.eccVal       = data.ecc;
   data.sfVal        = data.freq;
   attnParams        = fitHypothesis(data,group.avg.attn,attnInit);
   attnParams(:,3)   = attnParams(:,2);
   

%% Plot fit to attention modulation
   figure('Name',sprintf('Group-average attention: %s',upper(attention_type)),'position',[42 740 1243 208]); 
   fitSF = logspace(log10(0.25),log10(32),1e3);

for e = 1:numel(data.ecc)
   subplot(1,numel(data.ecc),e);
   
   % evaluate fit to attention effect
      fitAttn(e,:) = asymGaussian(log2(fitSF),attnParams(e,:));

   % draw line at no cueing effect
      line([0.125 32],[1 1],'color',[0.5 0.5 0.5],'linewidth',1.5); hold on
   
   % draw neutral peak SF and SEM
      % sem
      avg = group.avg.neut_peakSF(e); err = group.err.neut_peakSF(e);
      lb = avg-err; ub = avg+err;
      errrange = logspace(log10(lb),log10(ub),1e2);
      f = fill([errrange fliplr(errrange)],[ones(1,1e2) zeros(1,1e2)+1.3],'k'); hold on
      set(f,'FaceColor','k','FaceAlpha',0.25,'EdgeColor','none');

      % avg
      line([avg avg],[1 1.3],'color','k','linewidth',1.5); 
   
   % draw attention peak SF and SEM
   if strcmp(attention_type,'exo')
      % sem
      avg = group.avg.attn_peakSF(e); err = group.err.attn_peakSF(e);
      lb = avg-err; ub = avg+err;
      errrange = logspace(log10(lb),log10(ub),1e2);
      f = fill([errrange fliplr(errrange)],[ones(1,1e2) zeros(1,1e2)+1.3],color); hold on
      set(f,'FaceColor',color,'FaceAlpha',0.25,'EdgeColor','none');

      % avg
      line([avg avg],[1 1.3],'color',color,'linewidth',1.5); 
   end

   % plot fits
      semilogx(fitSF,fitAttn(e,:),'-','Linewidth',3,'color',color); hold on

   % plot raw data
      loglog(data.freq,squeeze(group.avg.attn(e,:)),'o','MarkerSize',5,'color','w'); hold on
      loglog(data.freq,squeeze(group.avg.attn(e,:)),'o','MarkerSize',4,'markerfacecolor',color,'markeredgecolor','none'); hold on
      errorbar(data.freq,group.avg.attn(e,:),group.err.attn(e,:),'Linestyle','none','Color',color,'Linewidth',2,'CapSize',0);

   % pretty up figure
      figureDefaults
      title(sprintf('%i deg',data.ecc(e)),'fontname','arial','fontsize',10);
      set(gca,'xlim',[0.25 20],'xtick',[0.5 1 2 4 8 16],'xticklabel',{'0.5' '1' '2' '4' '8' '16'},'ylim',[0.98 1.3],'ytick',[1 1.15 1.3],...
         'ticklength',[0.025 0.05],'xscale','log');
      if e==1
         xlabel('Spatial frequency (cpd)','fontname','arial','fontsize',10); 
         ylabel('Cueing effect (\Delta d^{\prime})','fontname','arial','fontsize',10);
      end
end
