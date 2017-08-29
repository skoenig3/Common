function parsed_eyedat = preparse(eyedat)
%break eye data up into chuncks of continuous eye data seperated by NaNs
parsed_eyedat = {};
x = eyedat(1,:);
y = eyedat(2,:);
if all(x(1) == x) || all(y(1) == y); %sometimes occur when basically looked away the whole time
    filler_nans = NaN(2,length(x));
    parsed_eyedat{1} = filler_nans;
else
    nanind = find(isnan(x));
    if isempty(nanind) %never looked outside of image
        parsed_eyedat{1} = [x;y];
    else %if looked outside of the image
        [outside_ind]=findgaps(nanind);
        if isempty(outside_ind);
            outside_ind = nanind;
        end
        remove_more = []; %if need to remove short abrupt looking in and outs
        for i = 1:size(outside_ind,1);
            last_ind = find_last_ind(outside_ind(i,:));
            if i == 1 && outside_ind(1,1) <= 200;
                remove_more = [remove_more 1:outside_ind(1,1)-1];
            end
            if i == size(outside_ind,1)
                if length(x) - outside_ind(i,last_ind) <= 200
                    remove_more  = [remove_more outside_ind(i,last_ind)+1:length(x)];
                end
            else
                if outside_ind(i+1,1)-outside_ind(i,last_ind) <= 200
                    remove_more = [remove_more outside_ind(i,last_ind)+1:outside_ind(i+1,1)-1];
                end
            end
        end
        nanind = sort([nanind remove_more]);
        [outside_ind]=findgaps(nanind);
        if isempty(outside_ind) %just so I can use outside_ind in the following lines of code
            outside_ind = nanind;
        end
        if sum(sum(outside_ind ~= 0)) == length(x) %if after removing short breaks thre's nothing left
            filler_nans = NaN(2,length(x));
            parsed_eyedat{1} = filler_nans;
        else
            index = 1;
            for i = 1:size(outside_ind); %since trials must start and end with eye data inside window
                if i == 1;
                    if outside_ind(1,1) ~= 1
                        parsed_eyedat{index} =[x(1:outside_ind(1,1)-1);...
                            y(1:outside_ind(1,1)-1)];
                        index = index+1;
                        last_ind = find_last_ind(outside_ind(1,:));
                        filler_nans = NaN(2,last_ind);
                        parsed_eyedat{index} = filler_nans;
                        index = index+1;
                        if size(outside_ind,1) == 1 && outside_ind(end) ~= length(x)
                            parsed_eyedat{index} =[x(outside_ind(end)+1:end);...
                                y(outside_ind(end)+1:end)];
                        end
                    else
                        last_ind = find_last_ind(outside_ind(1,:));
                        filler_nans = NaN(2,last_ind);
                        parsed_eyedat{index} = filler_nans;
                        index = index+1;
                        if size(outside_ind,1) == 1 && outside_ind(end) ~= length(x)
                            parsed_eyedat{index} =[x(outside_ind(end)+1:end);...
                                y(outside_ind(end)+1:end)];
                        end
                    end
                elseif i == size(outside_ind,1)
                    last_ind = find_last_ind(outside_ind(i-1,:));
                    parsed_eyedat{index} = [x(outside_ind(i-1,last_ind)+1:outside_ind(i,1)-1);...
                        y(outside_ind(i-1,last_ind)+1:outside_ind(i,1)-1)];
                    index = index+1;
                    last_ind = find_last_ind(outside_ind(end,:));
                    if outside_ind(i,last_ind) == length(x); %then last part of scan path is nans
                        last_ind = find_last_ind(outside_ind(end,:));
                        parsed_eyedat{index} = NaN(2,last_ind);
                    else
                        filler_nans = NaN(2,last_ind);
                        parsed_eyedat{index} = filler_nans;
                        index = index+1;
                        parsed_eyedat{index} = [x(outside_ind(end,last_ind)+1:end);...
                            y(outside_ind(end,last_ind)+1:end)];
                    end
                else
                    last_ind = find_last_ind(outside_ind(i-1,:));
                    parsed_eyedat{index} = [x(outside_ind(i-1,last_ind)+1:outside_ind(i,1)-1);...
                        y(outside_ind(i-1,last_ind)+1:outside_ind(i,1)-1)];
                    index = index+1;
                    last_ind = find_last_ind(outside_ind(i,:));
                    filler_nans = NaN(2,last_ind);
                    parsed_eyedat{index} = filler_nans;
                    index = index+1;
                end
            end
        end
    end
end
end
function last_ind = find_last_ind(outside_ind_row)
last_ind = find(outside_ind_row == 0);
if isempty(last_ind)
    last_ind = size(outside_ind_row,2);
else
    last_ind = last_ind(1)-1;
end
end

