function group_distractTask
addpath('../../../attnCSF/exo/anal');

%% Initialize key variables
subjList = {'AS' 'DT' 'MJ' 'SP' 'MM'};
cueCol = linspecer(10);

%% Load subject data
for s = 1:length(subjList)
   load(['../data/',subjList{s},'/homo/perf.mat']);   
   subjPerf(s,:,:,:) = avgPerf;
   subjThresh(s,:,:) = avgCSF;
   octaves(s,:,:) = octavesFromPeak(shiftdim(avgCSF,-1),sfVal);
end
subjPerf(subjPerf<0.5) = 0.5;

%% Compute group average
% proportion correct
group.pCorr.raw = subjPerf;
group.pCorr.avg = squeeze(mean(subjPerf,1));
group.pCorr.sem = withinSubjError(group.pCorr.raw,0);

% attention effect
group.attn.raw = squeeze(diff(subjPerf,[],2));
%group.attn.raw = squeeze(diff(subjPerf,[],2)./sum(subjPerf,2));
group.attn.avg = squeeze(mean(group.attn.raw));
group.attn.sem = withinSubjError(group.attn.raw,0);

% aligned to neutral peak
fullOctRange = round(unique(octaves(:))*1e2)./1e2;
group.align.raw = alignAttn(fullOctRange,octaves,group.attn.raw);
group.align.avg = squeeze(nansum(group.align.raw,1)./numel(subjList));
group.align.sem = withinSubjError(group.align.raw,0);
group.align.nsubj = numel(subjList)-squeeze(sum(isnan(group.align.raw),1));

% CSF
group.csf.raw = subjThresh;
group.csf.avg = exp(squeeze(mean(log(subjThresh),1)));
group.csf.sem = squeeze(std(1./subjThresh,[],1)./sqrt(numel(subjList)));

%% Plot group data
% CSF
figure('Name','Group: Neutral CSF');
for e = 1:numel(eccVal)
   leg(e) = loglog(sfVal,1./group.csf.avg(:,e),'.-','MarkerSize',15,'Linewidth',2,'Color',cueCol(e,:)); hold on
   errorbar(sfVal,1./group.csf.avg(:,e),group.csf.sem(:,e),'Color',cueCol(e,:),'Linestyle','none');
end
% pretty up figure
set(gca,'XTick',2.^(-2:4),'XLim',[0.4 20],'YLim',[0.4 250],'YTick',[1 10 100],'TickDir','out','box','off','YTickLabel',{'1' '10' '100'});
xlabel('Spatial frequency (cpd)'); ylabel('Sensitivity');
legend(leg,{'2' '6'});



% proportion correct for each eccentricity
for e = 1:numel(eccVal)
   figure('Name',['Group: proportion correct',num2str(eccVal(e))])
   %subplot(1,numel(eccVal),e)
   for c = 1:size(group.pCorr.avg,1)
      semilogx(sfVal,squeeze(group.pCorr.avg(c,:,e)),'.-','MarkerSize',15,'Linewidth',2,'Color',cueCol(c,:)); hold on
      errorbar(sfVal,squeeze(group.pCorr.avg(c,:,e)),squeeze(group.pCorr.sem(c,:,e)),'Color',cueCol(c,:),'Linestyle','none');
   end
   % pretty up figure
   set(gca,'XTick',2.^(-2:4),'XLim',[0.4 20],'YLim',[0.45 1],'box','off','TickDir','out','YTick',0:0.25:1);
   xlabel('Spatial frequency (cpd)'); ylabel('Proportion correct');
   line([1e-3 20],[0.75 0.75],'Color','r','Linestyle','--');
   line([1e-3 20],[0.5 0.5],'Color','k','Linestyle','--');
   title([num2str(eccVal(e)), ' deg']);
end



% attention effects for each eccentricity
for e = 1:numel(eccVal)
   figure('Name',['Group: attention effects', num2str(eccVal(e))]);
   %subplot(1,numel(eccVal),e)
   semilogx(sfVal,group.attn.avg(:,e),'.-','Color',cueCol(e,:),'MarkerSize',15,'Linewidth',2); hold on
   errorbar(sfVal,group.attn.avg(:,e),group.attn.sem(:,e),'Color',cueCol(e,:),'Linestyle','none');
   % pretty up figure
   set(gca,'XTick',2.^(-2:4),'XLim',[0.4 20],'YLim',[-0.12 0.12],'box','off','TickDir','out','YTick',-0.5:0.1:0.5);
   xlabel('Spatial frequency (cpd)'); ylabel('Valid-Neutral');
   line([1e-3 20],[0 0],'Color','k','Linestyle','--');
   title([num2str(eccVal(e)), ' deg']);
end


% aligned attention effects
sizePerSubj = 3;
for e = 1:numel(eccVal)
figure('Name',['Group: aligned attention',num2str(eccVal(e))]);
   %subplot(1,numel(eccVal),e)
   for point = 1:numel(fullOctRange)
      % plot points
      if group.align.nsubj(e,point)
         nOverlap = group.align.nsubj(e,point);
         plot(fullOctRange(point),group.align.avg(e,point),'.','Color',cueCol(e,:),'MarkerSize',nOverlap*sizePerSubj); hold on
         errorbar(fullOctRange(point),group.align.avg(e,point),group.align.sem(e,point),'Color',cueCol(e,:),'Linestyle','none');
      end
   end
   % plot line
   plot(fullOctRange,group.align.avg(e,:),'-','Color',cueCol(e,:),'Linewidth',1.5);
   % pretty up figure
   set(gca,'XTick',-4:2:4,'XLim',[-5 5],'YLim',[-0.12 0.12],'box','off','TickDir','out','YTick',-1:0.1:1);
   xlabel('Aligned to Neutral Peak (octaves)'); ylabel('Valid-Neutral');
   line([-10 10],[0 0],'Color','k','Linestyle','--');
   line([0 0],[-10 10],'Color','k','Linestyle','--');
   title([num2str(eccVal(e)), ' deg']);
end


