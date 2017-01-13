function B = circshift_row(A)
% circularlly shift each row in A by a random number of indexes. Function
% preserves matrix otherwise. Function is faster than Matlabs's circhift
% if done row by row and deals with NaNs and shifts appropriately.
% assumes NaNs are at the end of the data not sporadically  distributed!!!!
%
% Code rechecked for bugs January 11, 2017 SDK

if isempty(A)
    B = A;
elseif any(any(isnan(A))) 
    %ignore NaNs when shifting spike trains and preserve indeces, 
    %usually NaNs at start or end of indeces
    [m, n] = size(A);
    B = NaN(m, n);
    
    for i = (1 : m)
        n = sum(~isnan(A(i,:)));
        if n~=0 %if not all NaNs
            nanind = isnan(A(i,:)); %find which indeces are NaNs
            temp = A(i,~nanind); %take non-NaN values
            D = randi(length(temp)); %shift only non-NaN values
            temp = [temp(n - D + 1 : n) temp(1 : n - D)]; %shift only non-NaN values
            B(i,~nanind) = temp; %presereve NaN ind
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