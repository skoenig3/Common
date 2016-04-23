function [border_points] = Find_Edges(binary_matrix)
% created by  Seth Koning on 5/22/2014
%
%Function finds the edges of an object embedded into an "image". Object
%location must be defined by 1's where it is location and 0's where it is
%not. Object can be filled in completely or have holes. Holes will be
%detected as edges.
%
% Note edge output is exactly one pixel off the object. So object is
% > or < border NOT >= or <=

% Input: Binary Matrix
%
% Output: Edge locations [horizontal pixels, vertical pixels];

border_points = NaN(1,2);
[rows,cols]=size(binary_matrix);

%find if object touches horzontal edges of image
ind = find(binary_matrix(:,1) ~= 0);
if ~isempty(ind);
    border_points = [border_points; [ind,ones(length(ind),1)]];
end
ind = find(binary_matrix(:,end) ~= 0);
if ~isempty(ind);
    border_points = [border_points; [ind,size(binary_matrix,2)*ones(length(ind),1)]];
end

%find if object touches vertical edges of image
ind = find(binary_matrix(1,:) ~= 0);
if ~isempty(ind);
    border_points = [border_points; [ones(length(ind),1),ind']];
end

ind = find(binary_matrix(end,:) ~= 0);
if ~isempty(ind);
    border_points = [border_points; [size(binary_matrix,1)*ones(length(ind),1),ind']];
end

%if object doesn't touch borders...
%find vertical edges
binary_matrix2 = [binary_matrix(:,2:end) zeros(rows,1)];
[v_xind1,v_yind1] = find(binary_matrix2 > binary_matrix);

binary_matrix2 = [zeros(rows,1) binary_matrix(:,1:end-1)];
[v_xind2,v_yind2] = find(binary_matrix2 > binary_matrix);

%find horizontal edges
binary_matrix2 = [binary_matrix(2:end,:);zeros(1,cols)];
[h_xind1,h_yind1] = find(binary_matrix2 > binary_matrix);

binary_matrix2 = [zeros(1,cols); binary_matrix(1:end-1,:)];
[h_xind2,h_yind2] = find(binary_matrix2 > binary_matrix);

border_points = [border_points; ...
    [v_xind1,v_yind1];[h_xind1,h_yind1];...
    [v_xind2,v_yind2];[h_xind2,h_yind2]];

border_points(1,:) = [];