% Purpose:  Recreate Figure 10. 
%           Cueing effect across SF for exogenous and endogenous attention.
%
% By:       Michael Jigo
% Edited:   06.29.21
%
% Input:    attention_type    'exo' or 'endo'

function figure10(attention_type)
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
      group.avg.attn          = squeeze(nanmean(data.attn_effect,1));
      group.err.attn          = squeeze(std(data.attn_effect)./sqrt(size(data.attn_effect,1)));
      
   % Neutral peak SF
      group.avg.neut_peakSF   = mean(data.csf.peakSF,1);
      group.err.neut_peakSF   = withinSubjError(data.csf.peakSF);
      
   % Attention peak SF
      group.avg.attn_peakSF   = mean(2.^data.attn.centerSF,1);
      group.err.attn_peakSF   = withinSubjError(2.^data.attn.centerSF);


%% fit group-average attention effects
   for e = 1:numel(data.ecc)
      p = fit2asymGaussian(log2(data.freq),group.avg.attn(:,e),attnshape);
      p(3) = p(2);
      attnParams(e,:) = p;
   end


%% plot fit to attention modulation
   figure('Name',sprintf('Group-average attention: %s',upper(attention_type)),'position',[360 416 515 202]); 
   fitSF = logspace(log10(0.25),log10(32),1e3);

for e = 1:numel(data.ecc)
   subplot(1,numel(data.ecc),e);
   
   % evaluate fit to attention effect
      fitAttn(e,:) = asymGaussian(log2(fitSF),attnParams(e,:));

   % draw line at no cueing effect
      line([0.125 32],[0 0],'color',[0.5 0.5 0.5],'linewidth',1.5); hold on
   
   % draw neutral peak SF and SEM
      % sem
      avg = group.avg.neut_peakSF(e); err = group.err.neut_peakSF(e);
      lb = avg-err; ub = avg+err;
      errrange = logspace(log10(lb),log10(ub),1e2);
      f = fill([errrange fliplr(errrange)],[zeros(1,1e2) zeros(1,1e2)+0.6],'k'); hold on
      set(f,'FaceColor','k','FaceAlpha',0.25,'EdgeColor','none');

      % avg
      line([avg avg],[0 0.6],'color','k','linewidth',1.5); 
   
   % draw attention peak SF and SEM
   if strcmp(attention_type,'exo')
      % sem
      avg = group.avg.attn_peakSF(e); err = group.err.attn_peakSF(e);
      lb = avg-err; ub = avg+err;
      errrange = logspace(log10(lb),log10(ub),1e2);
      f = fill([errrange fliplr(errrange)],[zeros(1,1e2) zeros(1,1e2)+0.6],color); hold on
      set(f,'FaceColor',color,'FaceAlpha',0.25,'EdgeColor','none');

      % avg
      line([avg avg],[0 0.6],'color',color,'linewidth',1.5); 
   end

   % plot fits
      semilogx(fitSF,fitAttn(e,:),'-','Linewidth',3,'color',color); hold on

   % plot raw data
      errorbar(data.freq,group.avg.attn(:,e),group.err.attn(:,e),'Linestyle','none','Color',color,'Linewidth',2,'CapSize',0); hold on
      loglog(data.freq,squeeze(group.avg.attn(:,e))','o','MarkerSize',5,'color','w'); hold on
      loglog(data.freq,squeeze(group.avg.attn(:,e))','o','MarkerSize',4,'markerfacecolor',color,'markeredgecolor','none'); hold on

   % pretty up figure
      figureDefaults
      title(sprintf('%i deg',data.ecc(e)),'fontname','arial','fontsize',10);
      set(gca,'xlim',[0.25 20],'xtick',[0.5 1 2 4 8 16],'xticklabel',{'0.5' '1' '2' '4' '8' '16'},'ylim',[-0.05 0.6],'ytick',0:0.2:1,...
         'ticklength',[0.025 0.05],'xscale','log');
      if e==1
         xlabel('Spatial frequency (cpd)','fontname','arial','fontsize',10); 
         ylabel('Cueing effect (\Delta d^{\prime})','fontname','arial','fontsize',10);
      end
end
