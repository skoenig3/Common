function [blinks,nan_ind,time_out] = findbad_eye_ind(pupil,x,outside_tolerance)
% Written by Seth Konig July 10, 2015
% Code fines indeces in which monkey blinked and when monkey was looking
% away from the images (as indicated by nan_ind in the x,y data (only need x))
%
% time_out determines which is the last good index. If NaN then all
% indexes are good. Outisde_tolerance determines how much total time
% outside the image is ok. 1/3 of Outiside_tolerance is the max per
% incident
%
%
%---Find When the monkey Blinked---%
%pupil values at 0 diameter

%for novel
thresh = mean(pupil)-3.7*std(pupil);

blinks = find(pupil <= thresh);
blinks = findgaps(blinks);
if size(blinks,2) == 1;
    blinks = blinks';
end

blink_ind = [];%upsampled ind
if ~isempty(blinks)
    for b = 1:size(blinks,1)
        ind = blinks(b,:);
        ind(ind == 0) = [];
        blink_ind = [blink_ind (5*ind(1)-4):(5*ind(end)+4)];%center on up sampled bins
    end
    blink_ind(blink_ind > length(x)) = [];
end

%---Determine when monkey was looking away---%
%for novel
nan_ind = find(isnan(x));
nan_ind = findgaps(nan_ind);%get indices for each time eyes left the image

if ~isempty(nan_ind)
    total_out = 0;
    ind1 = 1;
    while total_out < outside_tolerance && ind1 <= size(nan_ind,1)
        out_time = nan_ind(ind1,:);
        out_time(out_time == 0) = [];
        if length(out_time) >= outside_tolerance/3 %too much for 1 instance
            ind1 = ind1+1;
            break
        end
        [c,~,~] = intersect(out_time,blink_ind);
        total_out = total_out + length(out_time)-length(c);
        ind1 = ind1+1;
    end
    if ind1 > size(nan_ind,1) %not enought time outside img really
        time_out = NaN;
    else
        time_out = nan_ind(ind1-1,1)-1;
        time_out(time_out < 5) = 5;
    end
else
    time_out = NaN;
end
end