% DO NOT ERASE SETH PLEAE READ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


slope = [];
intercept = [];
for i = 1:length(IOR_taus)
    if IOR_taus(i) == 0 || IOR_taus(i) == 50
        val = nanmean(salience_at_fixations{i}(:,1:40));
    elseif IOR_taus(i) < 7
        val = nanmean(salience_at_fixations{i}(:,1:19));
    else
        val = nanmean(salience_at_fixations{i}(:,1:IOR_taus(i)));
    end
    
    filtsal = filtfilt(1/7*ones(1,7),1,val);
    asymptote = val(end-1);%use filtered version to estimate asymtote
    
    val = val-asymptote;
    
    figure(12)
    hold on
    plot(val/max(val))
    hold off
    
    figure
    x = (0:length(val)-1)';
    y = val;
    f = fit(x,y','exp1')
    slope(i) = f.b;
    intercept(i) = f.a;
    try
        plot(f,x,y)
        title(['tau_{IOR} = 1/' num2str(IOR_taus(i))])
    catch
        continue
    end
    
end
%%
figure

colorset = hsv;
set(gca,'ColorOrder',colorset(end:-7:1,:))
hold all
for i = 2:length(IOR_taus)-1
    val = nanmean(salience_at_fixations{i}(:,1:40));
    filtsal = filtfilt(1/7*ones(1,7),1,val);
    asymptote = min(filtsal);%use filtered version to estimate asymtote
    val = val-asymptote;
    plot(val/max(val))
    
end
xlabel('Fixation Number')
ylabel('Normalized Salience')
labels= {'IOR Tau 0','IOR Tau 1/50','IOR Tau 1/35','IOR Tau 1/25',...
    'IOR Tau 1/17','IOR Tau 1/12','IOR Tau 1/7','IOR Tau 1/3','IOR Tau 1'};
legend(labels);