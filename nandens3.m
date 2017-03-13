function [mean_filtered_matrix,filtered_matrix] = nandens3(spmat,window,Fs)
halfwin = window/2;

x = -3*halfwin:halfwin*3;
kernel = exp(-0.5*x.^2/halfwin^2);% the std. dev. is the halfwin
kernel = kernel/sum(kernel);

spmat = spmat*Fs;

filtered_matrix = NaN(size(spmat));
for t = 1:size(spmat,1);
    vec = spmat(t,:);
    vecind = find(~isnan(vec));
    
    if isempty(vecind) %all NaNs
        continue
    end
    
    nnvec = vec(vecind);
    
    if length(nnvec) > 2*window
        
        
        padded_vec = [ones(1,1*2*window)*nanmean(nnvec(window*2:-1:1)) ...
            nnvec ones(1,1*2*window)*nanmean(nnvec(end:-1:(end-window*2+1)))]; %mirror padding
        %     padded_vec = [zeros(1,window*3) nnvec zeros(1,window*3)]; %zero padding
        
        padded_vec = conv(padded_vec,kernel,'same');
        
        filtered_matrix(t,vecind) = padded_vec(window*2+1:end-window*2);
    else
        filtered_matrix(t,vecind) = NaN; %remove
    end
    
end
mean_filtered_matrix = nanmean(filtered_matrix);
mean_filtered_matrix = filtfilt(1/5*ones(1,5),1,mean_filtered_matrix);%5 ms moving average to get rid of high frequency bumps
%due to different trial lengths

end