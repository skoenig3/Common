%---[11] Combine BCRW and Calculate Goodness of Fit-AUC ROC Fixation Order---%
scm_image_dir = 'C:\Users\seth.koenig\Documents\MATLAB\BCRW Salience Model\SCM Image Sets\';
image_sets = {'Set006','Set007','Set008','Set009',...
    'SetE001','SetE002','SetE003','SetE004'};
tags = {'MP','TT','JN','IW'};
imageX = 800;
imageY = 600;
binsize = 25; %code is optimized for binsize of 25 other values may produce fatal errors
f = fspecial('gaussian',[256,256],24);
parkhurst = {'on','rand','IOR','WTA'}; %distamce bias for fixation order in Parkhurst, Law, Niebur (2002)
for pk = 2%:length(parkhurst);
    
    %save set avearges
    ROC = cell(1,length(image_sets));
    all_salience_at_fixations = cell(1,length(image_sets));
    all_salience_at_random = cell(1,length(image_sets));
    all_BCRW_at_fixations = cell(1,length(image_sets));
    all_BCRW_at_random = cell(1,length(image_sets));
    all_I_at_fixations = cell(1,length(image_sets));
    all_I_at_random = cell(1,length(image_sets));
    medianlen = NaN(1,length(image_sets));

    for imset = 1%:length(image_sets);
        disp(['Image set-' num2str(image_sets{imset})])
        dirName = [scm_image_dir image_sets{imset}];
        cd(dirName)
        matfiles = what;
        

        salience_at_fixations = NaN(36*length(tags),100);
        salience_at_random = NaN(36*length(tags),100);
        BCRW_at_fixations = NaN(36*length(tags),100);
        BCRW_at_random = NaN(36*length(tags),100);
        I_at_fixations = NaN(36*length(tags),100);
        I_at_random = NaN(36*length(tags),100);
        numfixations = NaN(36*length(tags),1);

        
        eyedatafiles = zeros(1,length(tags));
        for i = 1:length(matfiles.mat);
            if ~isempty(strfind(matfiles.mat{i},'fixation.mat'))
                for ii = 1:length(tags);
                    if ~isempty(strfind(matfiles.mat{i},tags{ii}))
                        eyedatafiles(ii) = i;
                    end
                end
            end
        end
        
        for index = 1%:36;
            disp(['Running on image #' num2str(index) ' from ' image_sets{imset}])
            load([num2str(index) '-saliencemap.mat']);
            binsal = bin2(fullmap,binsize,binsize);
            binsal(binsal == 0) = min(min(fullmap));
            salorder = NaN(size(binsal));
            tempsal = binsal;
            [rr,cc] = meshgrid(1:imageX/binsize,1:imageY/binsize);
            fixnum = 1;
            i = 12.5;
            j = 16.5;
            while any(any(binsal > 0));
                if strcmpi(parkhurst{pk},'on')
                    tempsal = tempsal.*exp(-((rr-i).^2+(cc-j).^2)/(2*5^2));
                elseif strcmpi(parkhurst{pk},'rand')
                    tempsal = tempsal.*exp(-((rr-i).^2+(cc-j).^2)/(2*randi([1 10])^2));
                elseif strcmpi(parkhurst{pk},'IOR')
                    C = sqrt((rr-j).^2+(cc-i).^2)<=2;
                    tempsal(C == 1) = 0;
                end
                [i,j] = find(tempsal == max(max(tempsal)));
                if max(max(tempsal)) == 0;
                    binsal = zeros(size(binsal));
                    salorder(isnan(salorder)) = fixnum;
                elseif isempty(i)
                    binsal = zeros(size(binsal));
                    salorder(isnan(salorder)) = fixnum;
                    tempsal = binsal;
                else
                    if length(i) > 1;
                        ind = sub2ind(size(tempsal),i,j);
                        [~,ind2] = sort(binsal(ind),'descend');
                        ind = ind(ind2(1));
                        [i,j] = ind2sub(size(tempsal),ind);
                    end
                    salorder(i,j) = fixnum;
                    binsal(i,j) = 0;
                    tempsal = binsal;
                    tempsal(i,j) = 0;
                    fixnum = fixnum + 1;
                end
            end
            
            img = double(rgb2gray(imread([num2str(index) '.bmp'])));
            img = 256-img;
            binI = bin2(img,binsize,binsize);
            Iorder = NaN(size(binI));
            tempI = binI;
            [rr,cc] = meshgrid(1:imageX/binsize,1:imageY/binsize);
            fixnum = 1;
            i = 12.5;
            j = 16.5;
            while any(any(binI > 0));
                if strcmpi(parkhurst{pk},'on')
                    tempI = tempI.*exp(-((rr-i).^2+(cc-j).^2)/(2*5^2));
                elseif strcmpi(parkhurst{pk},'rand')
                    tempI = tempI.*exp(-((rr-i).^2+(cc-j).^2)/(2*randi([1 10])^2));
                elseif strcmpi(parkhurst{pk},'IOR')
                    C = sqrt((rr-j).^2+(cc-i).^2)<=2;
                    tempI(C == 1) = 0;
                end
                [i,j] = find(tempI == max(max(tempI)));
                if max(max(tempI)) == 0;
                    binI = zeros(size(binI));
                    Iorder(isnan(Iorder)) = fixnum;
                elseif isempty(i)
                    binI = zeros(size(binI));
                    Iorder(isnan(Iorder)) = fixnum;
                    tempI = binI;
                else
                    if length(i) > 1;
                        ind = sub2ind(size(tempI),i,j);
                        [~,ind2] = sort(binI(ind),'descend');
                        ind = ind(ind2(1));
                        [i,j] = ind2sub(size(tempI),ind);
                    end
                    Iorder(i,j) = fixnum;
                    binI(i,j) = 0;
                    tempI = binI;
                    tempI(i,j) = 0;
                    fixnum = fixnum + 1;
                end
            end
            
            maxfixations = 0;
            for t = 1:length(tags)
                load(['BCRW IOR TAU 35\' tags{t} '-' num2str(index) '-BCRW.mat'],'fixationtimes');
                maxfixations = max(maxfixations,max(sum(fixationtimes(:,:,1) > 0,2)));
            end
            fixorderpdf = zeros(imageY,imageX,maxfixations);
            allBCRW = zeros(imageY,imageX);
            for t = 1:length(tags)
                load(['BCRW IOR TAU 35\' tags{t} '-' num2str(index) '-BCRW.mat']);
                allBCRW = allBCRW + fixations;
                for i = 1:size(fixationtimes,1);
                    tind = find(fixationtimes(i,:,1) > 0);
                    for ii = 1:length(tind)
                        x = fixationtimes(i,tind(ii),1);
                        y = fixationtimes(i,tind(ii),2);
                        fixorderpdf(y,x,ii) =  fixorderpdf(y,x,ii) + 1;
                    end
                end
            end
            allBCRW = imfilter(allBCRW,f);
            binallBCRW = bin2(allBCRW,binsize,binsize);
            binfixorderpdf = zeros(imageY/binsize,imageX/binsize,maxfixations);
            for i = 1:maxfixations;
                binfixorderpdf(:,:,i) = bin2(fixorderpdf(:,:,i),binsize,binsize);
            end
            BCRWorder = NaN(imageY/binsize,imageX/binsize);
            for ii = 1:maxfixations
                [i,j,k] = ind2sub(size(binfixorderpdf),find(binfixorderpdf == max(max(max(binfixorderpdf)))));
                if length(k) > 1
                    mind = find(k == min(k));
                    i = i(mind);
                    j = j(mind);
                    k = k(mind);
                    if length(i) > 1
                        ind = sub2ind(size(binallBCRW),i,j);
                        [~,ind2] = sort(binallBCRW(ind),'descend');
                        ind = ind(ind2(1));
                        [i,j] = ind2sub([imageY/binsize,imageX/binsize],ind);
                        k = k(1);
                    end
                end
                binfixorderpdf(:,:,k) = 0;
                binfixorderpdf(i,j,:) = 0;
                BCRWorder(i,j) = k;
            end
            binallBCRW(~isnan(BCRWorder)) = NaN;
            tempBCRW = binallBCRW;
            [rr,cc] = meshgrid(1:imageX/binsize,1:imageY/binsize);
            fixnum = maxfixations+1;
            i = 12.5;
            j = 16.5;
            while any(any(binallBCRW > 0));
                if strcmpi(parkhurst{pk},'on')
                    tempBCRW = tempBCRW.*exp(-((rr-i).^2+(cc-j).^2)/(2*5^2));
                elseif strcmpi(parkhurst{pk},'rand')
                    tempBCRW = tempBCRW.*exp(-((rr-i).^2+(cc-j).^2)/(2*randi([1 10])^2));
                elseif strcmpi(parkhurst{pk},'IOR')
                    C = sqrt((rr-j).^2+(cc-i).^2)<=2;
                    tempBCRW(C == 1) = NaN;
                end
                [i,j] = find(tempBCRW == max(max(tempBCRW)));
                if isnan(min(min(tempBCRW)));
                    binallBCRW(isnan(BCRWorder)) = 0;
                    BCRWorder(isnan(BCRWorder)) = fixnum;
                elseif isempty(i)
                    binallBCRW(isnan(BCRWorder)) = 0;
                    BCRWorder(isnan(BCRWorder)) = fixnum;
                    tempBCRW = binallBCRW;
                else
                    if length(i) > 1;
                        ind = sub2ind(size(tempBCRW),i,j);
                        [~,ind2] = sort(binallBCRW(ind),'descend');
                        ind = ind(ind2(1));
                        [i,j] = ind2sub(size(tempBCRW),ind);
                    end
                    BCRWorder(i,j) = fixnum;
                    binallBCRW(i,j) = NaN;
                    tempBCRW = binallBCRW;
                    tempBCRW(i,j) = 0;
                    fixnum = fixnum + 1;
                end
            end
            
            for t = 1:length(tags)
                disp(['Running ' tags{t} ' on image #' num2str(index) ' from ' image_sets{imset}])
                if eyedatafiles(t) ~= 0;
                    load(matfiles.mat{eyedatafiles(t)})
                    fixations = fixationstats{index*2-1}.fixations;
                    if ~isempty(fixations)
                        if fixations(1,1) > imageX/2-100 && fixations(1,1) < imageX/2+100 &&...
                                fixations(2,1) < imageY/2+100 && fixations(2,1) > imageY/2-100
                            fixations(:,1) = [];
                        end
                        
                        loopindex = 36*(t-1)+index;
                        numfixations(loopindex) = size(fixations,2);
                        for iii = 1:size(fixations,2)
                            xxyy = fixations(:,iii);
                            xxyy(2) = imageY-xxyy(2);
                            xxyy = round((xxyy-binsize/2)/binsize+1);
                            xxyy(xxyy < 1) = 1;
                            xxyy(2,(xxyy(2) > size(binI,1))) = size(binI,1);
                            xxyy(1,(xxyy(1) > size(binI,2))) = size(binI,2);
                            
                            salience_at_fixations(loopindex,iii) = abs(salorder(xxyy(2),xxyy(1))-iii);
                            salience_at_random(loopindex,iii) =  abs(salorder(randi(numel(salorder)))-iii);
                            BCRW_at_fixations(loopindex,iii) = abs(BCRWorder(xxyy(2),xxyy(1))-iii);
                            BCRW_at_random(loopindex,iii) = abs(BCRWorder(randi(numel(salorder)))-iii);
                            I_at_fixations(loopindex,iii) = abs(Iorder(xxyy(2),xxyy(1))-iii);
                            I_at_random(loopindex,iii) = abs(Iorder(randi(numel(salorder)))-iii);
                        end
                    end
                end
            end
        end
        
        nans = find(isnan(nanmean(salience_at_fixations)));
        salience_at_fixations(:,nans) = [];
        salience_at_random(:,nans) = [];
        BCRW_at_fixations(:,nans) = [];
        BCRW_at_random(:,nans) = [];
        I_at_fixations(:,nans) = [];
        I_at_random(:,nans) = [];
        
        thresh = 0:1:numel(BCRWorder);
        TP = NaN(3,length(thresh)); %True positive
        FA = NaN(3,length(thresh)); %False alarm
        for fixnum = 1:size(salience_at_fixations,2);
            for ii = 1:length(thresh)
                len = sum(~isnan(salience_at_fixations(:,fixnum)));
                TP(1,ii) = sum(salience_at_fixations(:,fixnum) < thresh(ii))/len;
                FA(1,ii) = sum(salience_at_random(:,fixnum) < thresh(ii))/len;
                TP(2,ii) = sum(BCRW_at_fixations(:,fixnum) < thresh(ii))/len;
                FA(2,ii) = sum(BCRW_at_random(:,fixnum) < thresh(ii))/len;
                TP(3,ii) = sum(I_at_fixations(:,fixnum) < thresh(ii))/len;
                FA(3,ii) = sum(I_at_random(:,fixnum) < thresh(ii))/len;
            end
            ROC{imset}(1,fixnum) = trapz(FA(1,:),TP(1,:));
            ROC{imset}(2,fixnum) = trapz(FA(2,:),TP(2,:));
            ROC{imset}(3,fixnum) = trapz(FA(3,:),TP(3,:));
        end
        
        all_salience_at_fixations{imset} = nanmean(salience_at_fixations);
        all_salience_at_random{imset} = nanmean(salience_at_random);
        all_BCRW_at_fixations{imset} = nanmean(BCRW_at_fixations);
        all_BCRW_at_random{imset} = nanmean(BCRW_at_random);
        all_I_at_fixations{imset} = nanmean(I_at_fixations);
        all_I_at_random{imset} = nanmean(I_at_random);
        medianlen(imset) = nanmedian(numfixations);
        
    end

    medianlen = round(median(medianlen));
    
    figure
    hold on
    for imset = 1:length(image_sets)
        plot(1:medianlen,ROC{imset}(1,1:medianlen),'b')
        plot(1:medianlen,ROC{imset}(2,1:medianlen),'g')
        plot(1:medianlen,ROC{imset}(3,1:medianlen),'r')
    end
    hold off
    xlabel('Fixation Number')
    ylabel('AUC ROC (a.u.)')
    legend('Salience','BCRW','Image Intensity','location','Northeastoutside')
    xlim([0 medianlen])
    title(['Parkurst: ' parkhurst{pk}])
    
    
    figure
    hold on
    for imset = 1:length(image_sets)
        plot(1:medianlen,all_salience_at_fixations{imset}(1:medianlen),'b')
        plot(1:medianlen,all_BCRW_at_fixations{imset}(1:medianlen),'g')
        plot(1:medianlen,all_I_at_fixations{imset}(1:medianlen),'r')
    end
    hold off
    xlabel('Fixation Number')
    ylabel('Difference in Predicted and Actual fixation number')
    legend('Salience','BCRW','Image Intensity','location','Northeastoutside')
    xlim([0 medianlen])
    title(['Parkurst: ' parkhurst{pk}])
    
    if strcmpi(parkhurst{pk},'on')
        save(['C:\Users\seth.koenig\Documents\MATLAB\BCRW Salience Model\'...
            'SCM Image Sets\Combined-FixationOrder-parkhurst-Corrected-ImageI'],...
            'ROC','all_I_at_fixations','all_BCRW_at_fixations',...
            'all_salience_at_fixations','all_I_at_random','all_BCRW_at_random',...
            'all_salience_at_random','medianlen')
    elseif strcmpi(parkhurst{pk},'rand')
        save(['C:\Users\seth.koenig\Documents\MATLAB\BCRW Salience Model\'...
            'SCM Image Sets\Combined-FixationOrder-randparkhurst-Corrected-ImageI'],...
            'ROC','all_I_at_fixations','all_BCRW_at_fixations',...
            'all_salience_at_fixations','all_I_at_random','all_BCRW_at_random',...
            'all_salience_at_random','medianlen')
    elseif strcmpi(parkhurst{pk},'IOR')
        save(['C:\Users\seth.koenig\Documents\MATLAB\BCRW Salience Model\'...
            'SCM Image Sets\Combined-FixationOrder-IOR-Corrected-ImageI'],...
            'ROC','all_I_at_fixations','all_BCRW_at_fixations',...
            'all_salience_at_fixations','all_I_at_random','all_BCRW_at_random',...
            'all_salience_at_random','medianlen')
    elseif strcmpi(parkhurst{pk},'WTA')
        save(['C:\Users\seth.koenig\Documents\MATLAB\BCRW Salience Model\'...
            'SCM Image Sets\Combined-FixationOrder-WTA-Corrected-ImageI'],...
            'ROC','all_I_at_fixations','all_BCRW_at_fixations',...
            'all_salience_at_fixations','all_I_at_random','all_BCRW_at_random',...
            'all_salience_at_random','medianlen')
    else
        error('Method not recognized')
    end
end
