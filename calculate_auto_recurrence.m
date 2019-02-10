function [recurrence_rate,recurrence_map,corm,laminarity,laminarity_len,...
    forward_trace,forward_trace_len,reverse_trace,reverse_trace_len] = ...
    calculate_auto_recurrence(fixations,N_fix,dist_threshold)
%written Seth Konig 6/12/17
%code calculates basic recurrence measures for a scan path
%dist_threshold = 48 pixels or 2 dva
%N_fix using 40

if size(fixations,2) > N_fix
    fixations = fixations(:,1:N_fix);
end
N=size(fixations,2);

recurrence_map = zeros(N_fix);

[x,y]=meshgrid(1:N);
i=find(ones(N)); %forms pairs except for self-pairing
i=[x(i), y(i)];
dist =sqrt((fixations(1,i(:,1))-fixations(1,i(:,2))).^2 +...
    (fixations(2,i(:,1))-fixations(2,i(:,2))).^2);
dind = find(dist <= dist_threshold);
for d = 1:length(dind);
    recurrence_map(i(dind(d),1),i(dind(d),2)) = recurrence_map(i(dind(d),1),i(dind(d),2))+1;
end
R = sum(sum(triu(recurrence_map)))-N;%sum of pixels i.e. # of recurences
recurrence_rate = 100*2*R/N/(N-1);


%find diagonals
forward_trace = 0;
reverse_trace = 0;
for i = 1:N-1
    for ii = 2:N-1
        if ii > i
            if  recurrence_map(ii,i) == 1 && recurrence_map(ii+1,i+1) == 1%diagonal
                forward_trace = forward_trace+1;
            end
            if  recurrence_map(ii,i) == 1 && recurrence_map(ii-1,i+1) == 1%diagonal
                reverse_trace = reverse_trace+1;
            end
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
laminarity(tril(laminarity) == 1) = 0;
laminarity_len = sum(sum(laminarity,1) > 1);
laminarity = 100*(sum(sum(laminarity,1) > 1)+  sum(sum(laminarity,2) > 1))/2/R;

if sum(sum(recurrence_map)) < 3+N;
    corm = NaN;
else
    rm = recurrence_map;
    rm(tril(rm) == 1) = 0;
    [xcm,ycm] = centroid(rm);
    corm = xcm-ycm; %distance from unity line
end

end