d=dir('\\research.wanprc.org\research\Buffalo Lab\eblab\NEX files\SUA-VPC\aligned\*.nex');
clear filelist
for k=1:length(d)
    filelist(k,:)=d(k).name;
end
filelist=filelist(:,1:9);
%%
% fillop=strmatch('MP0803202',filelist)
fillop=strmatch('IW0604173',filelist)

fid=filelist(fillop,:)
dataWF=readNexFile(strcat('\\research.wanprc.org\research\Buffalo Lab\eblab\NEX files\SUA-VPC\aligned\',fid,'sua-aligned.nex'));
clear header
header.filename=fid;
i=1;
for k=1:size(dataWF.neurons,1)
    if size(strfind(dataWF.neurons{k}.name,'i'),2)~=2
        header.waves{i}=dataWF.waves{k}.waveforms';
        header.name{i}=dataWF.neurons{k}.name;
        i=i+1;
    end
end

celsel=1;
timarr=nan(size(header.waves{celsel}));
for k=1:size(header.waves{celsel},1)
    fndmin=find(header.waves{celsel}(k,:)==min(header.waves{celsel}(k,:)));
    timarr(k,:)=-(fndmin-1)*25:25:(32-fndmin)*25;
end

figure
for k=1:size(header.waves{celsel},1)
    hold on
    plot(timarr(k,:),header.waves{celsel}(k,:))
end

hold on
avgwav=nanmean(header.waves{celsel},1);
plot(-(find(avgwav==min(avgwav))-1)*25:25:(32-find(avgwav==min(avgwav)))*25,avgwav,'Color','k','LineWidth',3)

% xlim([-300 500])
xlim([-250 450])
set(gca,'TickDir','out')

