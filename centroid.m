function [xcm ycm] = centroid(matrix)
s = size(matrix);
totalmass = sum(sum(matrix));
xcm = sum(sum(matrix,1).*[1:s(2)])/totalmass;
ycm = sum(sum(matrix,2).*[1:s(1)]')/totalmass;
end