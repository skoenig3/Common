figure
subplot(1,2,1)
plot_average_recurrence_plots(all_pre_nov_recurence_map,1,25);
title('Nov')
clims1 = caxis;

subplot(1,2,2)
plot_average_recurrence_plots(all_pre_rep_recurence_map,0,25);
title('Rep')
clims2 = caxis;

cmin = min([clims1(1) clims2(1)]);
cmax = max([clims1(2) clims2(2)]);

subplot(1,2,1)
caxis([cmin cmax])
subplot(1,2,2)
caxis([cmin cmax])
