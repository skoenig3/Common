function [ax,h]=subtitle(text)
%
%Centers a title over a group of subplots.
%Returns a handle to the title and the handle to an axis.
% [ax,h]=subtitle(text)
% returns handles to both the axis and the title.
% ax=subtitle(text)
% returns a handle to the axis only.

ax=axes('Units','Normal','Position',[.1 .1 .85 .85],'Visible','off'); %was 0.075 0.075 instead of 0.1 0.1
set(get(ax,'Title'),'Visible','on')
title(text);
if (nargout < 2)
return
end
h=get(ax,'Title');