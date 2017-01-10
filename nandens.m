function [Dmean Dtrls] = nandens (spmat, window, type, fs, filttype)
% function [Dmean Dtrls] = nandens (spmat, window, type, fs)
%nkillian 100910 modified from density.m
%modfied from nandens to make filter width wider so less edge artifacts
%spmat is trls x samples
%window is window size in samples

if nargin < 5, filttype = 'nanflt';end

if window == 1,
    disp('call to nandens resulted in simple nanmean without filtering')
    Dmean = nanmean(spmat,1);
    Dtrls = spmat;
else   
    if nargin < 4
        warning('no fs supplied! using 1 kHz, set to 1 for simple convolution')
        fs = 1000;
    end
    
    % make sure the window is of even size
    % if doing gauss it actually gets a center sample
    % and is made odd
    if rem (window, 2)
        window = window + 1;
    end
    
    halfwin = window/2; %standard deviation
    [ntrls, samples] = size (spmat);
    
    if strcmp (type, 'gauss')
        x = -3*halfwin:halfwin*3;
        kernel = exp(-0.5*x.^2/halfwin^2);% the std. dev. is the halfwin
    elseif strcmp (type, 'boxcar')
        kernel = ones(1,window);
    else
        error ('type must be either ''gauss'' or ''boxcar''');
    end
    kernel = kernel/sum(kernel);
%     figure;plot(kernel);pause
    %get the density for all trials
    spmat = spmat*fs;%things per second now
 
    % working method below
    padded2(:,window+1 : samples+window) = spmat;
    gap = window + (length(kernel)-1)/2;
    
    %pad ends with avg value corresponding to halfwin:
    padded2(:,1:window)                                    = ones(ntrls,window) .* repmat(nanmean (spmat(:,1:window),2),1,window);
    padded2(:,size(padded2,2)+1:size(padded2,2)+window)    = ones(ntrls,window) .* repmat(nanmean (spmat(:,samples-window+1:samples),2),1,window);
    
    switch filttype
        case 'nanfltFullSum'
            tmp = ones(size(padded2)); sums = conv2(kernel,tmp);
            tmp(isnan(padded2)) = 0; 
            
            padded2(isnan(padded2)) = 0;
            
            Dtrls = conv2(kernel,padded2)./sums;
            Dtrls = Dtrls(:,gap+1:size(Dtrls,2)-gap);
                    
        case 'nanflt'
            % % %             %super slow:
            % % %             Dtrls = nan(size(padded2));
            % % %             for k = 1:size(padded2,1);
            % % %                 Dtrls(k,:) = nanfilt1(  padded2(k,:),kernel,1,1);
            % % %             end
            % % %             Dtrls = Dtrls(:,halfwin+1 : samples+halfwin);
            
            % super fast
            tmp = ones(size(padded2)); tmp(isnan(padded2)) = 0;
            sums = conv2(kernel,tmp);
            padded2(isnan(padded2)) = 0;
            Dtrls = conv2(kernel,padded2)./sums;
            Dtrls = Dtrls(:,gap+1:size(Dtrls,2)-gap);
            
        case 'convol'
            % traditional, doesn't handle nans correctly, kills anything with a nan in it
            Dtrls = conv2(kernel,padded2);
            Dtrls = Dtrls(:,gap+1:size(Dtrls,2)-gap);
            
    end
    Dmean = nanmean(Dtrls,1);
    if length(Dmean)~=size(spmat,2), error('check dimensions');end
end