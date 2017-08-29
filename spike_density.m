function [mean_filtered_matrix,filtered_matrix] = spike_density(spikeMat,sigma,Fs)
x = -3*sigma:sigma*3;%time vector, really only need to go out 3*sigma
kernel = exp(-0.5*x.^2/sigma^2);% the std. dev. is the sigma
kernel = kernel/sum(kernel); %normalize so sum of kernel is 1!


window = 2*sigma;
spikeMat = spikeMat*Fs; %if you want firing rate in spike/sec need to multiple by sampling frequency usually 1000 Hz

filtered_matrix = NaN(size(spikeMat));
for t = 1:size(spikeMat,1);%filter each trial (row) individually
    vec = spikeMat(t,:);
    padded_vec = [ones(1,1*2*window)*mean(vec(window*2:-1:1)) ...
        vec ones(1,1*2*window)*mean(vec(end:-1:(end-window*2+1)))]; %mirror padding
    padded_vec = conv(padded_vec,kernel,'same');%filtered trial
    filtered_matrix(t,:) = padded_vec(window*2+1:end-window*2);
end
mean_filtered_matrix = mean(filtered_matrix); %calculates average firing rate across trials
end