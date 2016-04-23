function B = circshift_row(A)
% circularlly shift each row in A by a random number of indexes. Function
% preserves matrix otherwise. Function is faster than Matlabs's circhift
% if done row by row and deals with NaNs and shifts appropriately.
% assumes NaNs are at the end of the data not sporadically  distributed!!!!
if isempty(A)
    B = A;
elseif any(any(isnan(A))) %if their are NaNs must be fillers to speed up computation
    [m, n] = size(A);
    B = NaN(m, n);
    
    for i = (1 : m)
        n = sum(~isnan(A(i,:)));
        if n~=0
            temp = A(i,1:n);
            D = randi(n);
            B(i,1:n) = [temp(n - D + 1 : n) temp(1 : n - D)];
        end
    end
else
    [m, n] = size(A);
    D = randi(n,1,m);
    B = zeros(m, n);
    
    for i = (1 : m)
        B(i,:) = [A(i,(n - D(i) + 1 : n)) A(i,(1 : n - D(i) ))];
    end
end
end