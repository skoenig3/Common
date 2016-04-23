function [rowpk colpk] = findpeaks2D(input,mindistbtwnpeaks)
% function uses simple peak detection based off of the gradient of a matrix
% and excludes peaks that are within a certain distance of each other as
% well as really tiny peaks
if nargin == 1
    mindistbtwnpeaks = 50;
end
[fx fy] = gradient(input);
peaksx = [NaN NaN];
for i = 1:size(fx,1);
    x = fx(i,:);
    pks = find((x(2:end) > 0 & x(1:end-1) < 0) | ((x(2:end) < 0 & x(1:end-1) > 0)));
    pks = [pks find((x(2:end-1) == 0 & x(1:end-2) < 0 & x(3:end) > 0)...
        |(x(2:end-1) == 0 & x(1:end-2) > 0 & x(3:end) < 0))];
    for ii = 1:length(pks);
        if input(i,pks(ii)) > 0;
            peaksx = [peaksx ; [i pks(ii)]];
        end
    end
end
peaksx2 = [];
for i = 1:size(fx,2);
    x = fx(:,i);
    pks = find((x(2:end) > 0 & x(1:end-1) < 0) | ((x(2:end) < 0 & x(1:end-1) > 0)));
    pks = [pks ; find((x(2:end-1) == 0 & x(1:end-2) < 0 & x(3:end) > 0)...
        |(x(2:end-1) == 0 & x(1:end-2) > 0 & x(3:end) < 0))];
    for ii = 1:length(pks);
        if input(pks(ii),i) > 0;
            peaksx2 = [peaksx2 ; [i pks(ii)]];
        end
    end
end

peaksy = [NaN NaN];
for i = 1:size(fx,1);
    x = fy(i,:);
    pks = find((x(2:end) > 0 & x(1:end-1) < 0) | ((x(2:end) < 0 & x(1:end-1) > 0)));
    pks = [pks find((x(2:end-1) == 0 & x(1:end-2) < 0 & x(3:end) > 0)...
        |(x(2:end-1) == 0 & x(1:end-2) > 0 & x(3:end) < 0))];
    for ii = 1:length(pks);
        if input(i,pks(ii)) > 0;
            peaksy = [peaksy ; [i pks(ii)]];
        end
    end
end

peaksy2 = [];
for i = 1:size(fx,2);
    x = fy(:,i);
    pks = find((x(2:end) > 0 & x(1:end-1) < 0) | ((x(2:end) < 0 & x(1:end-1) > 0)));
    pks = [pks; find((x(2:end-1) == 0 & x(1:end-2) < 0 & x(3:end) > 0)...
        |(x(2:end-1) == 0 & x(1:end-2) > 0 & x(3:end) < 0))];
    for ii = 1:length(pks);
        if input(pks(ii),i) > 0;
            peaksy2 = [peaksy2 ; [i pks(ii)]];
        end
    end
end

indx = sub2ind(size(input),peaksx(2:end,1),peaksx(2:end,2));
indx2 = sub2ind(size(input),peaksx2(2:end,2),peaksx2(2:end,1));
indy = sub2ind(size(input),peaksy(2:end,1),peaksy(2:end,2));
indy2 = sub2ind(size(input),peaksy2(2:end,2),peaksy2(2:end,1));
z = zeros(size(input));
z(indx) = 1;
z(indx2) = z(indx2)+1;
z(indy) = z(indy)+1;
z(indy2) = z(indy2)+1;
pks = find(z >= 2);
thresh = mean(input(pks));
pks(input(pks) < thresh) = []; %decreases processing times

[ix iy] = ind2sub(size(input),pks);
if length(ix) > 1;
    [rr cc] = meshgrid(1:length(ix),1:length(iy));
    N = ones(size(rr))-eye(size(rr));
    N = find(N);
    pairs = [rr(N) cc(N)];
    dist = sqrt((ix(pairs(:,1))-ix(pairs(:,2))).^2+(iy(pairs(:,1))-iy(pairs(:,2))).^2);
    
    shortdist = find(dist < mindistbtwnpeaks);
    rmv = [];
    for i = 1:length(shortdist)
        int1 = input(ix(pairs(shortdist(i),1)),iy(pairs(shortdist(i),1)));
        int2 = input(ix(pairs(shortdist(i),2)),iy(pairs(shortdist(i),2)));
        if int1 < int2
            rmv = [rmv; find(ix == ix(pairs(shortdist(i),1)) & iy == iy(pairs(shortdist(i),1)))];
        else
            rmv = [rmv; find(ix == ix(pairs(shortdist(i),2)) & iy == iy(pairs(shortdist(i),2)))];
        end
    end
    
    rmv = unique(rmv);
    ix(rmv) = [];
    iy(rmv) = [];
end

rowpk = ix;
colpk = iy;