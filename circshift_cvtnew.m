function B = circshift_cvtnew(A)
% written by Seth Konig 4/5/16
% swaps spike trains in 250 ms  sections to get shuffled data for the
% cvtnew task.

twin = 250; %size of spike trains blocks to shuffle

%determine index of each element in A
ind = reshape(1:numel(A),size(A))';
ind = ind(1:end);

%vectorize A
vector_A = A';
vector_A = vector_A(1:end); 

%remove nan indexs from A
ind(isnan(vector_A)) = [];
vector_A(isnan(vector_A)) = [];

%determine number of blocks in vector_A with block size twin
blocks = ceil(length(vector_A)/twin);
bind = 1:blocks;
bind = bind(randperm(blocks));%randomize order of blocks


% determine indeces for each block;
aind = [(0:blocks-2)' (1:blocks-1)'].*twin;
aind = [aind; [(blocks-1)*twin length(vector_A)]];
aind(:,1) = aind(:,1)+1;

%randomize indeces by block
aind = aind(bind,:);


%create shuffled vector
new_vector_A = NaN(1,length(vector_A));
last_index = 1;
for b = 1:blocks;
    new_vector_A(last_index:last_index+(aind(b,2)-aind(b,1))) = vector_A(aind(b,1):aind(b,2));
    last_index = last_index+(aind(b,2)-aind(b,1));
end


%put shuffled spike train back into matrix format
B = NaN(size(A));
B(ind) = new_vector_A;
