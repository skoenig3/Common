function [binnedmatrix] = bin1(matrix,step,upperlower,type)
% Function creates 1D binned vector by essentially scaling the down the
% columns by 'step' and averaging aross rows.
% INPUTS:
%   1) matrix: matrix you want to bin
%   2) step: bin size
%   3) upperlower: if 'upper' include any extra elements in an incomplete
%   extra bin (i.e. rounds up); if 'lower' exclude incomplete bin completely
%   ignoring values (i.e. rounds down).
%   4) Type:
%       a) 'sum': calculate the sum of the values for each bin (default)
%       b) 'mode': calculates the mode of the values for each bin
%       c) 'mean': calculates the mean of the values for each bin
% OUTPUT
%   1) Binned matrix!
%
% for 2D version see BIN2

if nargin < 4
    type = 'sum';
end
if nargin < 3
    upperlower = 'lower';
end
if nargin < 2
    step = 50;
end
if nargin == 0;
    error('Not enough inputs')
end

len = size(matrix,2);
if rem(len,step) ~= 0;
    if strcmpi(upperlower,'lower');
        bin = [0:step:len-step len];
    else
        bin = [0:step:len];
    end
else
    bin = [0:step:len];
end

binnedmatrix = zeros(1,length(bin)-1);
if strcmpi(type,'sum')
    for i = 1:length(bin)-1
        if i == 1
            binnedmatrix(i) = nansum(nansum(matrix(:,bin(1)+1:bin(2))));
        else
            binnedmatrix(i) = nansum(nansum(matrix(:,bin(i)+1:bin(i+1))));
        end
    end
elseif strcmpi(type,'mode')
    for i = 1:length(bin)-1
        if i == 1
            bm = matrix(:,bin(1)+1:bin(2));
            bm = bm(1:end);
            binnedmatrix(i) = mode(bm);
        else
            bm = matrix(:,bin(i)+1:bin(i+1));
            bm = bm(1:end);
            binnedmatrix(i) = mode(bm);
        end
    end
elseif strcmpi(type,'mean')
    for i = 1:length(bin)-1
        if i == 1
            binnedmatrix(i) = nanmean(nanmean(matrix(:,bin(1)+1:bin(2))));
        else
            binnedmatrix(i) = nanmean(nanmean(matrix(:,bin(i)+1:bin(i+1))));
        end
    end
else
    error('Unknown type of binning')
end