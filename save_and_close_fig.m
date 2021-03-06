function save_and_close_fig(figure_dir,filename)
% save_and_close_fig(figure_dir,filename)
%
% Written by Seth Konig August, 2014
% saves a fullscreen sized image to both .fig and .bmp formats to the
% directory specified by figure_dir
screen_size = get(0, 'ScreenSize');
set(gcf, 'Position', [0 0 screen_size(3) screen_size(4)]);

if ~isdir(figure_dir)
   mkdir(figure_dir) 
end


pause(0.5)%make sure time for matlab to re-render @ max figure size
saveas(gcf,[figure_dir filename '.fig']);
saveas(gcf,[figure_dir filename '.png']);
close
pause(0.1) %so closing occurs before next computation starts
end