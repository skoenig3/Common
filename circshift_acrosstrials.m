function B = circshift_acrosstrials(A)
% written by Seth Konig 4/3/16
% circularlly spike trains across all trials instead of within trials like
% circshift_row. preserves matrix otherwise.
%
% Code rechecked for bugs October 18, 2016 SDK

min_rot = 10*1000; %minimum of 10 seconds 
max_rot = sum(sum(~isnan(A)))-min_rot;

rot = randi([min_rot max_rot],1); %random rotation between min and max

%determine index of each element in A
ind = reshape(1:numel(A),size(A))';
ind = ind(1:end);

%vectorize A
vector_A = A';
vector_A = vector_A(1:end); 

%remove nan indexs from A
ind(isnan(vector_A)) = [];
vector_A(isnan(vector_A)) = [];

%rotate vector
vector_A = [vector_A(rot+1:end) vector_A(1:rot)];

%put shuffled spike train back into matrix format
B = NaN(size(A));
B(ind) = vector_A;
end