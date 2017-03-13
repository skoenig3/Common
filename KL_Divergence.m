function [Distance] = KL_Divergence(Fixation_Matrix1,Fixation_Matrix2)
% function calculates the symmetric KL Divergence between 2 fixation PDFs.
% This is calculating the similarity between the first and second matrix.
% Made by Seth Konig on 4/24/2014
%
% INPUT: 
%   1) Fixation_Matrix1: a zero matrix containing the locations of fixation
%   locations marked by a 1 where a fixation occured or marked by an
%   integer value for that number of fixations occuring in that location
%   (uncommon).
%   2) Fixation_Matrix2: same as Fixation_Matrix1 but for a different set
%   of fixations
%
% OUTPUT:
%   1) Distance: the value of KL Divergence in bits. 

f = fspecial('gaussian',[256 256],24); %~1 dva 2D gaussian filter for smoothing fixation locations

binsize=25;%for binning fixation PDF into ~1dva bins. Makes calculating KL-divergence faster

Fixation_Matrix1 = imfilter(Fixation_Matrix1,f); %smoothed
Fixation_Matrix1 = bin2(Fixation_Matrix1,binsize,binsize); %binned
Fixation_Matrix1(Fixation_Matrix1 == 0) = eps; %0's replaced with almost 0 i.e. 2^-52
Fixation_PDF1 = Fixation_Matrix1./sum(sum(Fixation_Matrix1)); %create PDF by dividing matrix by sum

Fixation_Matrix2 = imfilter(Fixation_Matrix2,f); %smoothed
Fixation_Matrix2 = bin2(Fixation_Matrix2,binsize,binsize); %binned
Fixation_Matrix2(Fixation_Matrix2 == 0) = eps; %0's replaced with almost 0 i.e. 2^-52
Fixation_PDF2 = Fixation_Matrix2./sum(sum(Fixation_Matrix2)); %create PDF by dividing matrix by sum

Distance = sum(sum(log2(Fixation_PDF1./Fixation_PDF2).*Fixation_PDF1))...
                        +sum(sum(log2(Fixation_PDF2./Fixation_PDF1).*Fixation_PDF2));
end