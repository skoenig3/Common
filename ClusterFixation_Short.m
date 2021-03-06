function [fixationstats] = ClusterFixation_Short(eyedat,samprate)
% Copyright 2013 Seth Koenig (skoenig3@uw.edu), Buffalo Lab
% Intellectual property owned by Emory University, all rights reserved.
% For non-commercial use only.

% Essentially the same as ClusterFixation_Final except use overlap of
% clusters in velocity/acceleratin state space to consolidate fixation
% clusters in BOTH global and local clustering instead of just local
% reclustering since so few data points that occur during short trials.
% There are not enough data points to do mean+3*std. Also uses 25
% replications instead 5.

% Function detects periods of fixations and saccades using k-means
% clustering. Code does not distinguish beteen saccades and micro-saccades.
% Periods of fixation are distinguished between periods of saccade using 4
% parameters dervied from Low Pass Filtered eye data that is resampled from
% 200 Hz to 1000 Hz. Parameters are distance, velocity, acceleration, and
% rotation. All parameters are necessary to increase the senitivity of the
% code. Clustering is initialy done on all data points (global clustering)
% during one presentation of images then clustering is redone on perviously
% detected fixations (local re-clustering) to increase sensitivtiy to small
% saccades. Saccades are required to be longer than 10 ms in duration and
% fixations are required to be longer than 25 ms in duration. Typically
% the only time that these durations are not met are during false
% classification at peak acclerations or velocities when having low values in
% the other parameter.These durations are free parameters (Lines 132,197,204).
%
% INPUTS:
%       eyedat: cell array aranged by trial containing [x;y] eye position in dva.
%       samprate: sampling rate in seconds of eyedat e.g. 1/(200 Hz)
%
% OUTPUTS:
%       fixationstats{cndlop}.fixationtimes = fixationtimes; indexes of fixation periods
%       fixationstats{cndlop}.fixations = fixations; mean position of fixation
%       fixationstats{cndlop}.saccadetimes = saccadetimes; indexes of saccade periods
%       fixationstats{cndlop}.FixationClusterValues = pointfix; values for whole fixation period
%                   1) max acceleration
%                   2) max velocity
%                   3) mean distance
%                   4) mean velocity
%                   5) mean absolute value of the angle
%                   6) mean rotation
%       fixationstats{cndlop}.SaaccadeClusterValues = pointsac; same as above except for saccades
%       fixationstats{cndlop}.MeanClusterValues = recalc_meanvalues; mean of parameter values by cluster
%       fixationstats{cndlop}.STDClusterValues = recalc_stdvalues; standard deviation of parameter values by cluster
%       fixationstats{cndlop}.XY = [x;y]; eye data from remapped to [0 to max size of image]

warning('off','stats:kmeans:EmptyCluster');%supress unneccessary warning message
warning('off','stats:kmeans:EmptyClusterInBatchUpdate');%supress unneccessary warning message
if nargin < 1;
    error('No data file found')
end
if nargin == 1;
    samprate = 5/1000; % in secs
end

fltord = 60;
lowpasfrq = 30;
nyqfrq = 1000 ./ 2;
flt = fir2(fltord,[0,lowpasfrq./nyqfrq,lowpasfrq./nyqfrq,1],[1,1,0,0]); %30 Hz low pass filter

buffer = 100/samprate/1000; %100 ms buffer for filtering
fixationstats = cell(1,length(eyedat));
for cndlop = 1:length(eyedat)
    if size(eyedat{cndlop},2) > 200/samprate/1000
        %---Filtering Extract Paramters from Eye Traces---%
        x = eyedat{cndlop}(1,:);%*24+400; %converts dva to pixel and data from [-400,400] to [0,800]
        y = eyedat{cndlop}(2,:);%*24+300; %converts dva to pixel and from [-300,300] to [0,600]
        x = [x(buffer:-1:1) x x(end:-1:end-buffer)]; %add buffer for filtering
        y = [y(buffer:-1:1) y y(end:-1:end-buffer)];   %add buffer for filtering
        x = resample(x,samprate*1000,1);%up sample to 1000 Hz
        y = resample(y,samprate*1000,1);%up sample to 1000 Hz
        xss = filtfilt(flt,1,x);
        yss = filtfilt(flt,1,y);
        xss = xss(101:end-100); %remove buffer after filtering
        yss = yss(101:end-100); %remove buffer after filtering
        x = xss; %remove buffer after filtering
        y = yss; %remove buffer after filtering
        velx = diff(xss);
        vely = diff(yss);
        vel = sqrt(velx.^2+vely.^2);
        accel = abs(diff(vel));
        angle = 180*atan2(vely,velx)/pi;
        vel = vel(1:end-1);
        rot = zeros(1,length(xss)-samprate*1000);
        dist = zeros(1,length(xss)-samprate*1000);
        for a = 1:length(xss)-2;
            rot(a) = abs(angle(a)-angle(a+1));
            dist(a) = sqrt((xss(a)-xss(a+2)).^2 + (yss(a)-yss(a+2)).^2);
        end
        rot(rot > 180) = rot(rot > 180)-180;
        rot = 360-rot; %want rotation to be small so fixation values are all small
        
        points = [dist' vel' accel' rot'];
        for ii = 1:size(points,2) %normalizes points to [0 1] by parameter
            thresh = mean(points(:,ii))+3*std(points(:,ii));%move outliers
            points((points(:,ii) > thresh),ii) = thresh;
            points(:,ii) = points(:,ii)-min(points(:,ii));
            points(:,ii) = points(:,ii)/max(points(:,ii));
        end
        
        %---Global Clustering---%
        sil = zeros(1,5); %determines the number of clusters by comparing the ratio
        %of intercluster and intracluster distances, faster mod of silhouette
        for numclusts = 2:5
            T = kmeans(points(1:10:end,2:4),numclusts,'replicate',5);
            [silh] = InterVSIntraDist(points(1:10:end,2:4),T);
            sil(numclusts) = mean(silh);
        end
        sil(sil > 0.9*max(sil)) = 1;
        numclusters = find(sil == max(sil));
         T = kmeans(points,numclusters(end),'replicate',25);
        rng = zeros(max(T),2*(size(points,2)-1));
        % determines fixation clusters by overlapping median values in velocity
        % and acceleration state space, here we DO NOT assume gaussian distributions
        % because there are not as many points and distributions rarely
        % are normal
        medianvalues = zeros(max(T),size(points,2));
        for TIND = 1:max(T);
            tc = find(T == TIND);
            if length(tc) == 1
                rng(TIND,:) = ones(1,size(rng,2));
                medianvalues(TIND,:) = points(tc,:);
            else
                rng(TIND,:) = [max(points(tc,1:end-1)) min(points(tc,1:end-1))];
                medianvalues(TIND,:) = median(points(tc,:));
            end
        end
        [~, fixationcluster] = min(sum(medianvalues(:,2:3),2));
        T(T == fixationcluster) = 100;
        fixationcluster2 = find((medianvalues(fixationcluster,2) < rng(:,2) & ...
            (medianvalues(fixationcluster,2) > rng(:,5))) & (medianvalues(fixationcluster,3)...
            < rng(:,3) & (medianvalues(fixationcluster,3) > rng(:,6))));
        fixationcluster2( fixationcluster2 == fixationcluster)= [];
        for iii = 1:length(fixationcluster2)
            T(T == fixationcluster2(iii)) = 100;
        end
        T(T ~= 100) = 2;
        T(T == 100) = 1;
        
        fixationindexes =  find(T == 1)';
        [fixationtimes] = BehavioralIndex(fixationindexes);
        fixationtimes(:,(diff(fixationtimes,1) < 25)) = []; %25 ms duration threshold
        
        %---Local Re-Clusteirng---%
        notfixations = [];
        for ii = 1:size(fixationtimes,2);
            %select points left and right of fixation for comparison
            altind = fixationtimes(1,ii)-50:fixationtimes(2,ii)+50;
            altind(altind < 1) = []; altind(altind > length(points)) = [];
            POINTS = points(altind,:); %does not re-nomralize
            sil = zeros(1,5);
            for numclusts = 1:5
                T = kmeans(POINTS(1:5:end,:),numclusts,'replicate',5);
                [silh] = InterVSIntraDist(POINTS(1:5:end,:),T);
                sil(numclusts) = mean(silh);
            end
            sil(sil > 0.9*max(sil)) = 1;
            numclusters = find(sil == max(sil));  %it's dangerous to have too many clusters
            T = kmeans(POINTS,ceil(median(numclusters)),'replicate',25);
            rng = zeros(max(T),2*(size(POINTS,2)-1));
            % determines fixation clusters by overlapping median values in velocity
            % and acceleration state space, here we DO NOT assume gaussian distributions
            % because there are not as many points and distributions rarely
            % are normal
            medianvalues = zeros(max(T),size(POINTS,2));
            for TIND = 1:max(T);
                tc = find(T == TIND);
                if length(tc) == 1
                    rng(TIND,:) = ones(1,size(rng,2));
                    medianvalues(TIND,:) = POINTS(tc,:);
                else
                    rng(TIND,:) = [max(POINTS(tc,1:end-1)) min(POINTS(tc,1:end-1))];
                    medianvalues(TIND,:) = median(POINTS(tc,:));
                end
            end
            [~, fixationcluster] = min(sum(medianvalues(:,2:3),2));
            T(T == fixationcluster) = 100;
            fixationcluster2 = find((medianvalues(fixationcluster,2) < rng(:,2) & ...
                (medianvalues(fixationcluster,2) > rng(:,5))) & (medianvalues(fixationcluster,3)...
                < rng(:,3) & (medianvalues(fixationcluster,3) > rng(:,6))));
            fixationcluster2( fixationcluster2 == fixationcluster)= [];
            for iii = 1:length(fixationcluster2)
                T(T == fixationcluster2(iii)) = 100;
            end
            T(T ~= 100) = 2;
            T(T == 100) = 1;
            notfixations = [notfixations altind(T == 2)];
        end
        
        %---Remove Points that are not fixations determing by Local Re-Clustering---%
        [~, ia, ~] = intersect(fixationindexes,notfixations);
        fixationindexes(ia) = [];
        saccadeindexes = 1:size(points,1);
        [~ , ~, ib] = intersect(fixationindexes,saccadeindexes);
        saccadeindexes(ib) = [];
        
        %---Consolidate & turn indexes into times---%
        if ~isempty(saccadeindexes)
            [saccadetimes] = BehavioralIndex(saccadeindexes);
        else
            saccadetimes = [];
        end
        [fixationtimes] = BehavioralIndex(fixationindexes);
        tooshort = find(diff(fixationtimes,1) < 5); %potential accidental fixationtimes
        %  yes, I purposelfully do not remove these times from fixationtimes!
        notbehav = [];
        for ii = 1:length(tooshort);
            notbehav = [notbehav fixationtimes(1,tooshort(ii)):fixationtimes(2,tooshort(ii))];
        end
        saccadeindexes = sort([saccadeindexes notbehav]);
        tooshort = find(diff(saccadetimes,1) < 10); %10 ms duration threshold for saccades
        notbehav = [];
        for ii = 1:length(tooshort);
            notbehav = [notbehav saccadetimes(1,tooshort(ii)):saccadetimes(2,tooshort(ii))];
        end
        fixationindexes = sort([fixationindexes notbehav]);
        [fixationtimes] = BehavioralIndex(fixationindexes);
        fixationtimes(:,(diff(fixationtimes,1) < 25))= []; %25 ms duration threshold for fixations
        fixationtimes(fixationtimes > length(x)) = length(x);
        fixationindexes = [];
        for ii = 1:size(fixationtimes,2);
            fixationindexes = [fixationindexes fixationtimes(1,ii):fixationtimes(2,ii)];
        end
        [fixationtimes, fixations] = BehavioralIndexXY(fixationindexes,x,y);
        
        saccadeindexes = 1:size(points,1);
        [~ , ~, ib] = intersect(fixationindexes,saccadeindexes);
        fixationindexes(fixationindexes > length(x)) = [];
        saccadeindexes(ib) = [];
        if ~isempty(saccadeindexes)
            [saccadetimes, ~] = BehavioralIndexXY(saccadeindexes,x,y);
        else
            saccadetimes = [];
        end
        
%         %---Return indexes to previous sampling rate & Calculate mean fixation position---%
%         round5 = rem(fixationtimes,samprate*1000);
%         round5(1,round5(1,:) > 0) = samprate*1000-round5(1,round5(1,:) > 0);
%         round5(2,:) = - round5(2,:);
%         fixationtimes = round((fixationtimes+round5)/(samprate*1000));
%         fixationtimes(fixationtimes < 1) = 1;
%         
%         round5 = rem(saccadetimes,samprate*1000);
%         round5(1,:) = - round5(1,:);
%         round5(2,round5(2,:) > 0) = samprate*1000-round5(2,round5(2,:) > 0);
%         saccadetimes = round((saccadetimes+round5)/(samprate*1000));
%         saccadetimes(saccadetimes < 1) = 1;
%         
%         x = eyedat{cndlop}(1,:);%*24+400;
%         y = eyedat{cndlop}(2,:);%*24+300;
%         saccadetimes(saccadetimes > length(x)) = length(x);
%         fixationtimes(fixationtimes > length(x)) = length(x);
        
        fixationstats{cndlop}.fixationtimes = fixationtimes;
        fixationstats{cndlop}.fixations = fixations;
        fixationstats{cndlop}.saccadetimes = saccadetimes;
        fixationstats{cndlop}.XY = [x;y];
    else
        x = eyedat{cndlop}(1,:);%*24+400; %converts dva to pixel and data from [-400,400] to [0,800]
        y = eyedat{cndlop}(2,:);%*24+300; %converts dva to pixel and from [-300,300] to [0,600]
        fixationstats{cndlop}.fixationtimes = [];
        fixationstats{cndlop}.fixations = [];
        fixationstats{cndlop}.saccadetimes = [];
        fixationstats{cndlop}.XY = [x;y];
    end
end

    function [behaviortime] = BehavioralIndex(behavind)
        %function turns indexes into times by parsing at breaks in continuity
        dind = diff(behavind);
        gaps =find(dind > 1);
        behaveind = zeros(length(gaps),50);
        if ~isempty(gaps)
            for gapind = 1:length(gaps)+1;
                if gapind == 1;
                    temp = behavind(1:gaps(gapind));
                elseif gapind == length(gaps)+1
                    temp = behavind(gaps(gapind-1)+1:end);
                else
                    temp = behavind(gaps(gapind-1)+1:gaps(gapind));
                end
                behaveind(gapind,1:length(temp)) = temp;
            end
        else
            behaveind =  behavind;
        end
        behaviortime = zeros(2,size(behaveind,1));
        for index=1:size(behaveind,1)
            rowfixind = behaveind(index,:);
            rowfixind(rowfixind == 0) = [];
            behaviortime(:,index) = [rowfixind(1);rowfixind(end)];
        end
    end

    function [behaviortime, behaviormean] = BehavioralIndexXY(behavind,x,y)
        %function is the same as above but also calculates mean fixation position
        dind = diff(behavind);
        gaps =find(dind > 1);
        behaveind = zeros(length(gaps),50);
        if ~isempty(gaps)
            for gapind = 1:length(gaps)+1;
                if gapind == 1;
                    temp = behavind(1:gaps(gapind));
                elseif gapind == length(gaps)+1
                    temp = behavind(gaps(gapind-1)+1:end);
                else
                    temp = behavind(gaps(gapind-1)+1:gaps(gapind));
                end
                behaveind(gapind,1:length(temp)) = temp;
            end
        else
            behaveind =  behavind;
        end
        behaviortime = zeros(2,size(behaveind,1));
        behaviormean = zeros(2,size(behaveind,1));
        for index=1:size(behaveind,1)
            rowfixind = behaveind(index,:);
            rowfixind(rowfixind == 0) = [];
            behaviortime(:,index) = [rowfixind(1);rowfixind(end)];
            behaviormean(:,index) = [mean(x(rowfixind));...
                mean(y(rowfixind))];
        end
    end

    function [silh] = InterVSIntraDist(X, clust)
        %Inter vs Intra distance points by cluster-mod of SILHOUETTE (just doesn't plot
        %by Seth Koenig October 21, 2012
        [idx,cnames] = grp2idx(clust);
        n = length(idx);
        k = length(cnames);
        count = histc(idx(:)',1:k);
        mbrs = (repmat(1:k,n,1) == repmat(idx,1,k));
        
        % Get avg distance from every point to all (other) points in each cluster
        myinf = zeros(1,1,class(X));
        myinf(1) = Inf;
        avgDWithin = repmat(myinf, n, 1);
        avgDBetween = repmat(myinf, n, k);
        for j = 1:n
            distj = sum((X - X(repmat(j,n,1),:)).^2, 2);
            % Compute average distance by cluster number
            for i = 1:k
                if i == idx(j)
                    avgDWithin(j) = sum(distj(mbrs(:,i))) ./ max(count(i)-1, 1);
                else
                    avgDBetween(j,i) = sum(distj(mbrs(:,i))) ./ count(i);
                end
            end
        end
        
        % Calculate the silhouette values
        minavgDBetween = min(avgDBetween, [], 2);
        silh = (minavgDBetween - avgDWithin) ./ max(avgDWithin,minavgDBetween);
        s = silh;
    end
end