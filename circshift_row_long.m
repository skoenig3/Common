function B = circshift_row_long(A)
% written by Seth Konig 11/29/16
% modified from circshift_row and circshift_acrosstrials
% circularlly spike trains within each image trials without ruining spike
% structure; preserves matrix otherwise.

min_rot = 200; %minimum of 200 ms, aka average fixaiton duration
if isempty(A)
    B = A;
else
    B = NaN(size(A));
    for trial = 1:size(A,1);

        vector_A = A(trial,:); %this trial
        if all(isnan(vector_A));
            continue
        end
        max_rot = sum(~isnan(vector_A))-min_rot;
        
        rot = randi([min_rot max_rot],1); %random rotation between min and max
        
        %determine index of each element in A
        ind = 1:length(vector_A);

        %remove nan indexs from A
        ind(isnan(vector_A)) = [];
        vector_A(isnan(vector_A)) = [];
        
        %rotate vector
        vector_A = [vector_A(rot+1:end) vector_A(1:rot)];
        
        %put shuffled spike train back into matrix format
        B(trial,ind) = vector_A;
    end
end
end