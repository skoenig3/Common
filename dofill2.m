function [hgt h hh ysmth y] = dofill2(x,y,color,dim,smval,bars,filloff,transp,fs,frate,useSEM)
%same as dofill but uses nandens3 which does smoothing trial by trial
%instead of matrix which works better for variable length trials! Modified SDK 11/17/2016
%dofill(x,y,color,dim,smval,bars,filloff)
%plot mean y-x curve and sem as polygon region
%alpha levels for shading are by default '1' to allow saving to eps
%x: a row vector of x values
%y: a matrix of trials x values
%dim: the dimension of trials or channels to average, default 1
%smval: how much to smooth the average, default 1
%bars: (0/1) plot using error bars instead of polygons
%filloff: (0/1) don't do the fill, just the means
%transp: (0/1) make fill transparent, keep off if sending to adobe ill.

%example for testing:
% spikes = rand(100,2000);time = 0.001:0.001:2;figure;dofill(time,spikes,'red',1,60)

if isempty(x) || isempty(y)
    return
end
if size(x,1) == 1;
    x = x';
end

%nathan killian 100912
if nargin < 11, useSEM = 1; end% use SEM or 95% conf intv
if nargin < 10, frate = 0;  end%plot as firing rate
if nargin < 9, fs = 1000;      end% sampling rate
if nargin < 8, transp = 1;  end
if nargin < 7, filloff = 0; end
if nargin < 6, bars = 0;    end
if nargin < 5, smval = [];  end
if nargin < 4, dim = 1;     end
if nargin < 3, color = 'b'; end
if nargin == 1, y = x; x = 1:size(x,2);end
if dim == 2, y = y';dim = 1;end

y(isinf(y)) = nan;

x = makerow(x);
m1 = max((nanmean(y,2)));m2 = max((nanmean(y,2)));
maxval = max([m1 m2]);
minval = min([nanmean(y,2);nanmean(y,2)]);

if ~isempty(smval)
    if ~frate, fs = 1000;end
    if any(any(isnan(y)))
        [ysmth y]   = nandens3(y,smval,fs);%smval = window full width
    else
        [ysmth y]   = nandens3(y,smval,fs);%smval = window full width
    end            
else
    disp('not smoothing!')
    ysmth       = nanmean(y,dim);
end
y(isinf(y)) = nan;ysmth(isinf(ysmth)) = nan;


badcols = [];
numtrls = zeros(1,size(y,2));
for di = 1:size(y,2)
    if nnnan(y(:,di))==0
        badcols = [badcols di];
    end
    numtrls(1,di) = length(find(~isnan(y(:,di))));
    if isnan(numtrls(1,di)) | isinf(numtrls(1,di)) | (numtrls(1,di)==0), badcols = [badcols di];end
end
xorig = x;yorig = y;ysmthorig = ysmth;
badcols = unique(badcols);
y(:,badcols) = [];x(badcols) = [];
numtrls(badcols) = [];
ysmth(badcols) = [];
% numtrls = size(y,1);

% calc SEM after any smoothing
if useSEM
    semvals = nanstd(y,0,dim)./sqrt(numtrls);
else %95% conf intv
    semvals = 1.96*nanstd(y,0,dim)./sqrt(numtrls);
end

sempos = ysmth+semvals;
semneg = ysmth-semvals;

if any(isnan(sempos)|isnan(semneg)), warning('nans in the error values');end


hgt = [min(semneg) max(sempos)];

vertices_x = [x'; flipud(x')];
if size(sempos,1)>size(sempos,2)
    vertices_y = [sempos; flipud(semneg)];
else
    vertices_y = [sempos'; flipud(semneg')];
end
if ~filloff
    if bars
        hh(3) = plot(x,ysmth,'color',color,'linewidth',2);hold on;
        seml = zeros(size(semneg));semu = zeros(size(sempos));
        %         ds = 4;
        ds = 1;%downsampling of the bars if necessary, 1 = no downsamp
        seml(1:ds:end) = semneg(1:ds:end);semu(1:ds:end) = sempos(1:ds:end);
        semneg = seml;sempos = semu;
        if ~isstr(color),    color = color/2;end
        
        hh(4) = line([x;x],[semneg;sempos],'color',color);
    else
        hold on;
        if transp
            %             whos vertices_x
            %             whos vertices_y
            %             whos ysmth
            hh(1) = fill(vertices_x,vertices_y, color, 'facealpha',.4, 'edgecolor',color,'edgealpha',0,'linewidth',eps);%edge must be 0 for multiple dudes on one plot
        else
            hh(2) = fill(vertices_x,vertices_y, color, 'facealpha',1, 'edgecolor',color,'edgealpha',0,'linewidth',eps);
        end
        h(1) = plot(x,ysmth,'color',color);
        %         hold on;
    end
    set(h,'handlevisibility','off')
else
    disp('not plotting error bars')
    h(2)= plot(x,ysmth,'color',color,'linewidth',2);hold on;
end

% RETURN THE ORIGINAL SMOOTHED DATA WITHOUT BAD COLUMNS REMOVED
x = xorig;y = yorig;ysmth = ysmthorig;

