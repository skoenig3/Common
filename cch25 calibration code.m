%Calibrate cch25 data

clrchng_cortexfile = 'XX#####.#'; %filename such as TO160506.1

samprate = 5;
imageX = 800;
imageY = 600;

if strcmpi(clrchng_cortexfile(1:2),'PW')
    clrchng_cortexfile = ['\\research.wanprc.org\research\Buffalo Lab\Cortex Data\Vivian\' clrchng_cortexfile];
elseif strcmpi(clrchng_cortexfile(1:2),'TT')
    clrchng_cortexfile = ['\\research.wanprc.org\research\Buffalo Lab\Cortex Data\Timmy\' clrchng_cortexfile];
elseif strcmpi(clrchng_cortexfile(1:2),'RR')
    clrchng_cortexfile = ['\\research.wanprc.org\research\Buffalo Lab\Cortex Data\Red\' clrchng_cortexfile];
elseif strcmpi(clrchng_cortexfile(1:2),'TO')
    clrchng_cortexfile = ['\\research.wanprc.org\research\Buffalo Lab\Cortex Data\Tobii\' clrchng_cortexfile];
elseif strcmpi(clrchng_cortexfile(1:2),'WR')
    clrchng_cortexfile = ['\\research.wanprc.org\research\Buffalo Lab\Cortex Data\Wilbur\' clrchng_cortexfile];   
end

%%----Color Change Calibration----%%
ITMFile = '\\research.wanprc.org\research\Buffalo Lab\eblab\Cortex Programs\ClrChng\cch25.itm';
CNDFile = '\\research.wanprc.org\research\Buffalo Lab\eblab\Cortex Programs\ClrChng\cch25.cnd';
% this is different becasue the spacing is different and I don't have
% a new item file on the network for the new spacing
ind_spacex = [-6,-3,0,3,6]; %whats on the network
ind_spacey = [-6,-3,0,3,6];%whats on the network
spacex = [-12,-6,0,6,12];%what actually gets displayed
spacey = [-8,-4,0,4,8];%what actually gets displayed
[time_arr,event_arr,eog_arr,~,~,~] = get_ALLdata(clrchng_cortexfile);

itmfil=[];
h =fopen(ITMFile);
tline = 1;
while tline > 0
    tline = fgetl(h);
    if ~isempty(itmfil)
        if length(tline)>size(itmfil,2)
            tline=tline(1:size(itmfil,2));
        end
    end
    tline = [tline ones(1,(size(itmfil,2)-length(tline)))*char(32)];
    if ischar(tline)
        itmfil=[itmfil; tline];
    else
        break
    end
end
fclose(h);

cndfil=[];
h=fopen(CNDFile);
tline = 1;
while tline > 0
    tline = fgetl(h);
    if ~isempty(cndfil)
        if length(tline)>size(cndfil,2)
            tline=tline(1:size(cndfil,2));
        end
    end
    tline = [tline ones(1,(size(cndfil,2)-length(tline)))*char(32)];
    if ischar(tline)
        cndfil=[cndfil; tline];
    else
        break
    end
end
fclose(h);

itmlist = zeros(size(cndfil,1)-1,1);
for i = 2:size(cndfil,1);
    str = textscan(cndfil(i,:),'%d');
    itmlist(i-1) = str{1}(end);
end


numrpt = size(event_arr,2);
valrptcnt = 0;
clear per clrchgind
for rptlop = 1:numrpt
    if itmlist(event_arr((find(event_arr(:,rptlop)>1000,1,'last')),rptlop)-1000) <= 189
        if size(find(event_arr(:,rptlop) == 200)) ~=0
            perbegind = find(event_arr(:,rptlop) == 24);%was originally 23, changed this and begtimdum line below to optimize
            perendind = find(event_arr(:,rptlop) == 24);
            if length( perbegind) > 1
                perbegind = perbegind(2);
                perendind = perendind(2);
            end
            cndnumind = find(event_arr(:,rptlop) >= 1000 & event_arr(:,rptlop) <=2000);
            blknumind = find(event_arr(:,rptlop) >=500 & event_arr(:,rptlop) <=999);
            begtimdum = time_arr(perbegind,rptlop)-100;
            endtimdum = time_arr(perendind,rptlop);
            if endtimdum > begtimdum
                valrptcnt = valrptcnt + 1;
                clrchgind(valrptcnt)=rptlop;
                per(valrptcnt).begsmpind = begtimdum;
                per(valrptcnt).endsmpind = endtimdum;
                per(valrptcnt).cnd = event_arr(cndnumind,rptlop);
                per(valrptcnt).blk = event_arr(blknumind,rptlop);
                per(valrptcnt).allval = event_arr(:,rptlop);
                per(valrptcnt).alltim = time_arr(:,rptlop);
                per(valrptcnt).event = rptlop;
            end
        end
    end
end

%Don't keep first 2 calibration pionts these are for offset correction at
%start of task
clear cnd
numrpt = size(per,2);
cnd = zeros(1,numrpt);
for rptlop = 1:numrpt
    cnd(rptlop)=per(rptlop).cnd;
end

% Create structures x and y of the corresponding average eye data for each trial
% instance (l) of each condition (k)

x = cell(length(spacex),length(spacey));%---For Calibration with Eye tracking data with cp2tform---%
y = cell(length(spacex),length(spacey));
control = NaN(length(cnd),2);
clr = ['rgbmkrgbmkrgbmkrgbmkrgbmkrgbmkrgbmkrgbmkrgbmkrgbmkrgbmkrgbmkrgbmkrgbmkrgbmk'];
figure
hold on
for k = 1:length(cnd)
    C = textscan(itmfil(itmlist(cnd(k)-1000)+5,:),'%d');
    control(k,:) = C{1}(9:10)';
    
    xi = find(C{1}(9) == ind_spacex);
    yi = find(C{1}(10) == ind_spacey);
    eyeind = floor(((per(k).begsmpind-1000)/samprate)*2):(floor((per(k).endsmpind-1000)/samprate))*2;
    evenind = eyeind(logical(~rem(eyeind,2)));
    oddind =  eyeind(logical(rem(eyeind,2)));
    x{xi,yi} = [x{xi,yi} mean(eog_arr(oddind,per(k).event))];
    y{xi,yi} = [y{xi,yi} mean(eog_arr(evenind,per(k).event))];
    plot(mean(eog_arr(oddind,per(k).event)),mean(eog_arr(evenind,per(k).event)),[clr(xi*yi) '+'])
end
if iscell(clrchng_cortexfile)
    title(['Calibration transformation for ' clrchng_cortexfile{1}(end-9:end)])
else
    title(['Calibration transformation for ' clrchng_cortexfile(end-9:end)])
end

%Test for errors%
count = zeros(length(spacey),length(spacex));
for xi = 1:length(spacex);
    for yi = 1:length(spacey);
        count(yi,xi) = sum(control(:,1) == spacex(xi) & control(:,2) == spacey(yi));
    end
end
if any(count < 5);
    disp('Calibration trial analysis incomplete or error')
    disp('Check number of calibration pionts or task not finished')
end

clear meanx meany
for k=1:numel(x)
    xss = x{k};
    low = mean(xss)-std(xss);
    high = mean(xss)+std(xss);
    xss(xss < low) = [];
    xss(xss > high) = [];
    meanx(k)=median(xss);
end
for k=1:numel(y)
    yss = y{k};
    low = mean(yss)-std(yss);
    high = mean(yss)+std(yss);
    yss(yss < low) = [];
    yss(yss > high) = [];
    meany(k)=median(y{k});
end

controlx = [];
controly = [];
for i = 1:length(spacex);
    for ii = 1:length(spacey);
        controly = [controly spacey(i)];
        controlx = [controlx spacex(ii)];
    end
end

newx = [];
newy = [];
figure
hold on
for i = 1:length(controlx);
    plot(controlx(i),controly(i),'r+')
    [x,y] = tformfwd(tform,meanx(i),meany(i));
    plot(x,y,'*b')
    newx(i) = x;
    newy(i) = y;
end
if iscell(clrchng_cortexfile)
    title(['Calibration transformation for ' clrchng_cortexfile{1}(end-9:end)])
else
    title(['Calibration transformation for ' clrchng_cortexfile(end-9:end)])
end
xlim([-17.5 17.5])
ylim([-12.5 12.5])

tform = get_calibration_fcn([controlx' controly'], [meanx' meany']);


% %---Recalibrate and automatically scale eye data---%
% % once you've imported from somewhere else
% for eye = 1:length(eyedat)
%     x = eyedat{eye}(1,:);
%     y = eyedat{eye}(2,:);
%     [x,y] = tformfwd(tform,x,y);
%     eyedat{eye} = [x;y];
% end
