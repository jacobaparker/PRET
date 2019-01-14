function fhs = pret_plot_boots(boots,model,options)
% pret_plot_boots(boots,model)
% fhs = pret_plot_boots(boots,model)
% fhs = pret_plot_boots(boots,model,options)
% options = pret_plot_boots()
% 
% Plots box and whisker plots of each parameter that was estimated as part
% of the bootstrapping procedure. Box shows median and 50% confidence
% interval, whiskers show 95% confidence interval, and remaining values are
% plotted as single points. Generates one figure per parameter type.
% 
% NOTE: Will close all figures currently open.
% 
%   Inputs:
%       
%       boots = boots structure output by pret_bootstrap containing the
%       parameter estimates for each bootstrap iteration.
% 
%       model = model structure created by pa_model and filled in by user.
%       Parameter values in model.ampvals, model.boxampvals, model.latvals,
%       model.tmaxval, and model.yintval do NOT need to be provided.
% 
%   Outputs:
% 
%       fhs = figure array containing handles for every plot generated.
% 
%   Options:
% 
%       pret_model_check = options for pret_model_check
% 
% Jacob Parker 2018

close all

if nargin < 3
    opts = pret_default_options();
    options = opts.pret_plot_boots;
    clear opts
    if nargin < 1
        fhs = options;
        return
    end
end

%OPTIONS
pret_model_check_options = options.pret_model_check;

%check input
pret_model_check(model,pret_model_check_options)

%boots vs model
if any(boots.eventtimes ~= model.eventtimes) || any(boots.window ~= model.window) || boots.samplerate ~= model.samplerate || length(boots.boxtimes) ~= length(model.boxtimes)
    warning('Information in "boots" does not seem to match information in "model", check inputs\n')
end

for bx = 1:length(boots.boxtimes)
    if any(boots.boxtimes{bx} ~= model.boxtimes{bx})
        warning('Information in "boots" does not seem to match information in "model", check inputs\n')
    end
end

fhs = gobjects(0);

if model.ampflag
    
    %amplitude plot
    fhs = [fhs figure];
    set(gcf,'Position',[100 100 560 420])
    hold on
    xlim([0 length(boots.eventtimes)+1])
    for ev = 1:length(boots.eventtimes)
        boxwhisker(boots.ampvals(:,ev),ev)
    end
    set(gca,'FontSize',12)
    set(gca,'XTick',1:length(boots.eventtimes))
%     xticks(1:length(boots.eventtimes))
    set(gca,'XTickLabel',model.eventlabels)
%     xticklabels(model.eventlabels)
    set(gca,'XTickLabelRotation',45)
%     xtickangle(45)
    xlabel('Event','FontSize',16)
    ylabel('Amplitude (% change from baseline)','FontSize',16)
    title('Event Amplitude Bootstrap Estimates','FontSize',16)
    
end

if model.latflag
    
    %latency plot
    fhs = [fhs figure];
    set(gcf,'Position',[200 100 560 420])
    hold on
    xlim([0 length(boots.eventtimes)+1])
    for ev = 1:length(boots.eventtimes)
        boxwhisker(boots.latvals(:,ev),ev)
    end
    set(gca,'FontSize',12)
    set(gca,'XTick',1:length(boots.eventtimes))
%     xticks(1:length(boots.eventtimes))
    set(gca,'XTickLabel',model.eventlabels)
%     xticklabels(model.eventlabels)
    set(gca,'XTickLabelRotation',45)
%     xtickangle(45)
    xlabel('Event','FontSize',16)
    ylabel('Latency (ms)','FontSize',16)
    title('Event Latency Bootstrap Estimates','FontSize',16)
end

if model.boxampflag
    
    %box amplitude plot
    fhs = [fhs figure];
    set(gcf,'Position',[300 100 560 420])
    hold on
    xlim([0 length(boots.boxtimes)+1])
    for bx = 1:length(boots.boxtimes)
        boxwhisker(boots.boxampvals(:,bx),bx)
    end
    set(gca,'FontSize',12)
    set(gca,'XTick',1:length(boots.boxtimes))
%     xticks(1:length(boots.boxtimes))
    set(gca,'XTickLabel',model.boxlabels)
%     xticklabels(model.boxlabels)
    set(gca,'XTickLabelRotation',45)
%     xtickangle(45)
    xlabel('Event','FontSize',16)
    ylabel('Amplitude (% change from baseline)','FontSize',16)
    title('Box Amplitude Bootstrap Estimates','FontSize',16)
    
end

if model.tmaxflag
    
    %tmax plot
    fhs = [fhs figure];
    set(gcf,'Position',[400 100 560 420])
    hold on
    xlim([0 2])
    boxwhisker(boots.tmaxvals,1)
    set(gca,'FontSize',12)
    set(gca,'XTick',1)
%     xticks(1)
    set(gca,'XTickLabel',{'t_{max}'})
%     xticklabels({'t_{max}'})
    ylabel('Time (ms)','FontSize',16)
    title('t_{max} Bootstrap Estimates','FontSize',16)
    
end

if model.yintflag

    %y-intercept plot
    fhs = [fhs figure];
    set(gcf,'Position',[500 100 560 420])
    hold on
    xlim([0 2])
    boxwhisker(boots.yintvals,1)
    set(gca,'FontSize',12)
    set(gca,'XTick',1)
%     xticks(1)
    set(gca,'XTickLabel',{'y-intercept'})
%     xticklabels({'y-intercept'})
    ylabel('Amplitude (% change from baseline)','FontSize',16)
    title('y-intercept Bootstrap Estimates','FontSize',16)

end

if model.slopeflag

    %y-intercept plot
    fhs = [fhs figure];
    set(gcf,'Position',[600 100 560 420])
    hold on
    xlim([0 2])
    boxwhisker(boots.slopevals,1)
    set(gca,'FontSize',12)
    set(gca,'XTick',1)
%     xticks(1)
    set(gca,'XTickLabel',{'slope'})
%     xticklabels({'y-intercept'})
    ylabel('Amplitude/time (% change/ms)','FontSize',16)
    title('slope Bootstrap Estimates','FontSize',16)

end


    function boxwhisker(x,g)
        % draws single vertical box and whsiker plot from distribution x at x axis
        % value of g with median, 50% CI box, and 95% CI whiskers.
        w = 0.5;
        lw = 1.5;
        
        xmed = nanmedian(x);
        x25 = prctile(x,25);
        x75 = prctile(x,75);
        x2p5 = prctile(x,2.5);
        x97p5 = prctile(x,97.5);
        xout = x(x < x2p5 | x > x97p5);
        
        hold on
        
        plot([g g],[x75 x97p5],'--k','LineWidth',lw)
        plot([g-w/2 g+w/2],[x97p5 x97p5],'k','LineWidth',lw)
        
        plot([g g],[x2p5 x25],'--k','LineWidth',lw)
        plot([g-w/2 g+w/2],[x2p5 x2p5],'k','LineWidth',lw)
        
        plot([g-w/2 g+w/2],[xmed xmed],'r','LineWidth',lw)
        
        plot([g-w/2 g+w/2],[x25 x25],'b','LineWidth',lw)
        plot([g-w/2 g+w/2],[x75 x75],'b','LineWidth',lw)
        plot([g-w/2 g-w/2],[x25 x75],'b','LineWidth',lw)
        plot([g+w/2 g+w/2],[x25 x75],'b','LineWidth',lw)
        
        plot(g*ones(1,length(xout)),xout,'+k','MarkerSize',6)
    end

end