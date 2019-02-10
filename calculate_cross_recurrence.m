function [recurrence_rate,recurrence_map,corm,laminarity,laminarity_len,...
    forward_trace,forward_trace_len,reverse_trace,reverse_trace_len,N_used] = ...
    calculate_cross_recurrence(fixations1,fixations2,N_fix,dist_threshold)
%written Seth Konig 10/23/2017 adapted from calculate_auto_recurrence
%code calculates basic recurrence measures for a scan path
%may need some adapting since auto is different that cross

N = min([size(fixations1,2) size(fixations2,2)]);
if N > N_fix
    N = N_fix;
end
fixations1 = fixations1(:,1:N);
fixations2 = fixations2(:,1:N);
N_used = N;

recurrence_map = zeros(N_fix);

[x,y]=meshgrid(1:N);
i=find(ones(N)); %forms pairs except for self-pairing
i=[x(i), y(i)];
dist =sqrt((fixations1(1,i(:,1))-fixations2(1,i(:,2))).^2 +...
    (fixations2(2,i(:,1))-fixations2(2,i(:,2))).^2);
dind = find(dist <= dist_threshold);
for d = 1:length(dind);
    recurrence_map(i(dind(d),1),i(dind(d),2)) = recurrence_map(i(dind(d),1),i(dind(d),2))+1;
end
R = sum(sum(recurrence_map));%sum of pixels i.e. # of recurences
recurrence_rate = 100*R/N^2;


%find diagonals
forward_trace = 0;
reverse_trace = 0;
for i = 1:N-1
    for ii = 2:N-1
            if  recurrence_map(ii,i) == 1 && recurrence_map(ii+1,i+1) == 1%diagonal
                forward_trace = forward_trace+1;
            end
            if  recurrence_map(ii,i) == 1 && recurrence_map(ii-1,i+1) == 1%diagonal
                reverse_trace = reverse_trace+1;
            end
    end
end

%find diagonal lengths
forward_trace_len = NaN(1,forward_trace);
reverse_trace_len = NaN(1,reverse_trace);

diag_count = 0;
reverse_diag_count = 0;
for dg = 1:N_fix-1;
    idn = eye(N_fix);
    idn = [idn(dg+1:end,:); zeros(dg,N_fix)];
    idnind = find(idn == 1);
    vals = 2*recurrence_map(idnind);
    if sum(vals) > 4
        gaps = findgaps(vals);
        if any(sum(gaps,2) > 4)
            for g = 1:size(gaps,1)
                gp = gaps(g,:);
                gp(gp == 0) = [];
                if length(gp) > 1
                    diag_count = diag_count+1;
                    forward_trace_len(diag_count) = length(gp);
                end
            end
        end
    end
    idn = idn(end:-1:1,:);
    idnind = find(idn == 1);
    vals = 2*recurrence_map(idnind);
    if sum(vals) > 4
        gaps = findgaps(vals);
        if any(sum(gaps,2) > 4)
            for g = 1:size(gaps,1)
                gp = gaps(g,:);
                gp(gp == 0) = [];
                if length(gp) > 1
                    reverse_diag_count = reverse_diag_count+1;
                    reverse_trace_len(reverse_diag_count) = length(gp);
                end
            end
        end
    end
end
forward_trace_len = nanmean(forward_trace_len);
reverse_trace_len = nanmean(reverse_trace_len);


forward_trace = 100*forward_trace/R;
reverse_trace = 100*reverse_trace/R;


%find horizontal and vertical lines
laminarity = recurrence_map;
laminarity_len = sum(sum(laminarity,1) > 1)+sum(sum(laminarity,2) > 1);
laminarity = 100*(sum(sum(laminarity,1) > 1)+  sum(sum(laminarity,2) > 1))/R;

if sum(sum(recurrence_map)) < N/3;
    corm = NaN;
else
    rm = recurrence_map;
    [xcm,ycm] = centroid(rm);
    corm = xcm-ycm; %distance from unity line
end

end