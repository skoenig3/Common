%% Old List Section
%for fixations out->in vs out->out
firing_rate_in_out = fix_locked_firing(fix_in_out == 1 | fix_in_out == 4,:);
in_or_out = fix_in_out(fix_in_out == 1 | fix_in_out == 4);
in_curve = nandens(firing_rate_in_out(in_or_out == 1,:),smval,'gauss',Fs,'nanflt');
out_curve = nandens(firing_rate_in_out(in_or_out == 4,:),smval,'gauss',Fs,'nanflt');
all_curves = NaN(numshuffs,twin1+twin2);
parfor shuff = 1:numshuffs;
    ind = randperm(length(in_or_out));
    shuff_in_or_out = in_or_out(ind);
    shuff_in_curve = nandens(firing_rate_in_out(shuff_in_or_out == 1,:),smval,'gauss',Fs,'nanflt');
    shuff_out_curve = nandens(firing_rate_in_out(shuff_in_or_out == 4,:),smval,'gauss',Fs,'nanflt');
    all_curves(shuff,:) = shuff_in_curve-shuff_out_curve;
end
list_95_curve{1,unit} = prctile(all_curves,95,1);
sig_ind = find((in_curve-out_curve) > list_95_curve{1,unit});

y_list = in_curve;
in_curve = in_curve-nanmean(in_curve(1:twin1));
in_curve = in_curve/max(in_curve);
[PKS,LOCS]= findpeaks(in_curve,'MinPeakWidth',40);
if ~isempty(LOCS)
    %remove peaks less than 1/2 the max
    LOCS(PKS < 0.66) = [];
    PKS(PKS < 0.66) = [];
end
if ~isempty(LOCS)
    PKS = PKS(1);
    LOCS = LOCS(1);
end

if ~isempty(LOCS)
    contextual_gain(1,unit) = LOCS; %location
    contextual_gain(2,unit) = in_curve(LOCS); %peak firing rate
end

%% Old Sequence Section
imgy = size(place_field_matrix,1);
%Determine if any of the items are inside the matrix or not?
sequence_inside = zeros(2,4);
for c = 1:4
    for seq = 1:2
        yloc = imgy-sequence_locations{seq}(2,c);
        xloc = sequence_locations{seq}(1,c);
        if place_field_matrix(yloc,xloc) == 1 %item is in field
            %then check if item is on border of field, if yes don't
            %count
            if place_field_matrix(yloc-1,xloc) == 1&& place_field_matrix(yloc-1,xloc-1) == 1 &&...
                    place_field_matrix(yloc-1,xloc+1) == 1 && place_field_matrix(yloc+1,xloc) == 1 && ...
                    place_field_matrix(yloc+1,xloc-1) == 1 && place_field_matrix(yloc+1,xloc+1) == 1 && ...
                    place_field_matrix(yloc,xloc+1) == 1 && place_field_matrix(yloc,xloc-1) == 1
                sequence_inside(seq,c) =1;
            else
                sequence_inside(seq,c) = NaN; %don't want to use border for any category
            end
        end
    end
end


%    %only want items that are out->out or out->in for comparison similar to
%    %above
%     nanify = [];
%     for c = 2:4  %allow item 1 no matter what since eye position probably offscreen anyway
%         for seq = 1:2
%                if sequence_inside(seq,c-1) == 1
%                    nanify = [nanify [seq; c]];
%                end
%         end
%     end
%
%     for i = 1:size(nanify,2)
%        sequence_inside(nanify(1,i),nanify(2,i)) = NaN;
%     end

if any(sequence_inside(:) == 1) && any(sequence_inside(:) == 0)
    seq_in_out = [];
    fixation_firing = [];
    for c = 1:4
        fixation_firing = [fixation_firing; sequence_fixation_locked_firing{c,unit}];
        for seq = 1:2
            if  sequence_inside(seq,c) == 1;
                seq_in_out = [ seq_in_out ones(1,sum(which_sequence(trial_nums{c,unit}) == seq))];
                %                 elseif isnan(sequence_inside(seq,c))
                %                     seq_in_out = [ seq_in_out NaN(1,sum(which_sequence(trial_nums{c,unit}) == seq))];
            else
                seq_in_out = [ seq_in_out zeros(1,sum(which_sequence(trial_nums{c,unit}) == seq))];
            end
        end
    end
    in_out_sequence{unit} = seq_in_out;
    
    in_curve = nandens(fixation_firing(seq_in_out == 1,:),smval,'gauss',Fs,'nanflt');
    out_curve = nandens(fixation_firing(seq_in_out == 0,:),smval,'gauss',Fs,'nanflt');
    all_curves = NaN(numshuffs,twin1+twin2);
    parfor shuff = 1:numshuffs;
        ind = randperm(length(seq_in_out));
        shuff_in_or_out = seq_in_out(ind);
        shuff_in_curve = nandens(fixation_firing(shuff_in_or_out == 1,:),smval,'gauss',Fs,'nanflt');
        shuff_out_curve = nandens(fixation_firing(shuff_in_or_out == 0,:),smval,'gauss',Fs,'nanflt');
        all_curves(shuff,:) = shuff_in_curve-shuff_out_curve;
    end
    sequence_95_curve{1,unit} = prctile(all_curves,97.5,1);
    sequence_95_curve{2,unit} = prctile(all_curves,2.5,1);
    seq_sig_ind = find((in_curve-out_curve) > sequence_95_curve{1,unit} | (in_curve-out_curve) < sequence_95_curve{2,unit});
end