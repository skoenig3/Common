function [cleaned] = laundry(dirty,dimension)
% written by Seth Konig August, 2014
% remove excess NaNs that fill all rows and/or all cols in a matrix
% dimeions 1 for row, 2 for col
%
% Code rechecked for bugs October 17, 2016 SDK

if nargin == 1
    dimension = [];
elseif dimension ~= 1 && dimension ~= 2
    error('Please use appropriate 2 dimesional values')
end

if isempty(dimension) %do row and col cleanup
    if iscell(dirty); %if cell clean up each matrix within cell
        for row = 1:size(dirty,1);
            for col = 1:size(dirty,2)
                if ~isempty(dirty{row,col})
                    nanrows = (sum(isnan(dirty{row,col}),2) == size(dirty{row,col},2));
                    dirty{row,col}(nanrows,:) = [];
                    nancols = (sum(isnan(dirty{row,col}),1) == size(dirty{row,col},1));
                    dirty{row,col}(:,nancols) = [];
                end
            end
        end
    else
        if size(dirty,1) == 1 || size(dirty,2) == 1 %row or column vector
            dirty(isnan(dirty)) = [];
        else
            nanrows = (sum(isnan(dirty),2) == size(dirty,2));
            dirty(nanrows,:) = [];
            nancols = (sum(isnan(dirty),1) == size(dirty,1));
            dirty(:,nancols) = [];
        end
    end
else %assumes cell/matrix
    if iscell(dirty);
        if dimension == 1 %clean by row
            for row = 1:size(dirty,1);
                for col = 1:size(dirty,2)
                    nanrows = (sum(isnan(dirty{row,col}),2) == size(dirty{row,col},2));
                    dirty{row,col}(nanrows,:) = [];
                end
            end
        elseif dimension == 2 %clean by col
            for row = 1:size(dirty,1);
                for col = 1:size(dirty,2)
                    nancols = (sum(isnan(dirty{row,col}),1) == size(dirty{row,col},1));
                    dirty{row,col}(:,nancols) = [];
                end
            end
        end
    else
        if size(dirty,1) == 1 || size(dirty,2) == 1 %row or column vector
            dirty(isnan(dirty)) = [];
        else
            if dimension == 1;
                nanrows = (sum(isnan(dirty),2) == size(dirty,2));
                dirty(nanrows,:) = [];
            elseif dimensions == 2
                nancols = (sum(isnan(dirty),1) == size(dirty,1));
                dirty(:,nancols) = [];
            end
        end
    end
end
cleaned = dirty;
end