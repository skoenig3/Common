function trialdata = analyze_sequence_trial(fixationstats,item_locations,fixwin,...
    event_codes,event_times)
% written by Seth Konig January 25, 2015
% function analyzes sigle trial data from the sequence task. For sucessful
% trials only. 
%
% Inputs:
%   1) fixationstats: for 1 trial
%   2) item_locations: location of items in sequence [x;y] and column by item #
%   3) fixwin: size of recatangular fixation window/tolerance
%   4) event_codes: cortex events
%   5) event_times: time cortex produced those codes/events occred
%   6) recording: true or false to determine if "time" in eye data needs to
%   be upsampled
%
% Outputs:
%   1) trialdata
%       a) trialdata.fixationnums: fixation number associated with each item #
%       b) trialdata.t2f: time to fixation by item #
%       c) trialdata.accuracy: accuracy of fixation by item #
%       d) trialdata.extrafixations: # of extra fixations by item #
%       e) trialdata.fixation_duration: fixation duraiton by item #
%       f) trialdata.time_to_leave: how long after item disapears before a saccade
%       g) trialdata.cortexpredict: 1's if cortex said truly predictive
%       h) trialdata.cortext2f: time to fixation according to cortex
%       i) trialdata.cortexbreak: whether monkey broke then refixated


%---Important Cortex Codes---%
eye_data_start_code = 100; %when xy eye data can be aligned to event codes, usually off by ~1000 ms
item_on_off_codes = [23 25 27 29; 24 26 28 30];%row 1, item on, row 2 item off, columb by item#
start_wait_fix_code = 11;%#ok<NASGU> %cortex is wating  for items to be fixated 
fixation_code = 8;%monkey fixated an item
break_fixation_code = 209;%monkey breaks fixation on an item

%---Cortex Codes for predictive timing files ckwenp.tim---%
% does not apply or effect processing for non-predictive sessions
started_predicted_code = 19; %eye was in fixwin before item turned on
broke_predicted_code = 265; %break fixation error on predicted eyemovment or False alarm
predicted_code = 20;%eye was in fixwin at least for 50 ms before item turned on

%---get the important eyedat from Cluster Fix's output---%
fixations = fixationstats.fixations;
fixationtimes = fixationstats.fixationtimes;
saccadetimes = fixationstats.saccadetimes;
xy = fixationstats.XY;
eye_data_start = event_times(event_codes == eye_data_start_code)-1;%-1 so index starts at 1 not 0

%---Preallocated Space for the ouptut---%
trialdata.fixationnums=NaN(1,4) ;%fixation number associated with each item #
trialdata.t2f=NaN(1,4) ;%time to fixation by item #
trialdata.accuracy=NaN(1,4) ;%fixation accuracy by item #
trialdata.extrafixations=NaN(1,4) ;%# of extra fixations by item #
trialdata.fixation_duration=NaN(1,4) ;%fixation duraiton by item #
trialdata.time_to_leave=NaN(1,4) ;%how long after item disapears before a saccade
trialdata.cortexpredict=NaN(1,4) ;%1's if cortex said truly predictive
trialdata.cortext2f=NaN(1,4) ;%time to fixation according to cortex
trialdata.cortexbreak=NaN(1,4);% whether monkey broke then refixated

if size(fixations,2) < 4
    disp('Not enough fixations found, skipping trial')
    return %not enough fixations detected in this trail. it should happen only rarely
end
%---determine which fixation was for which item in the sequence---%
fixation_number_on_item = NaN(1,4); %the ordinal fixation number on that item
fixation_accuracy = NaN(1,4);%how close was the fixation to the center of the item
for item = 1:4
    if item == 1;
        valid_window = [1 event_times(event_codes == item_on_off_codes(2,item))-eye_data_start];
    else
        valid_window = [event_times(event_codes == item_on_off_codes(2,item-1))...
            event_times(event_codes == item_on_off_codes(2,item))]-eye_data_start;
    end
    if valid_window(2) > length(xy)
        disp('error: probably have an indexing issue')
    end
    
    %find fixations that occur within a time period between the last item
    %on (or trial start if 1st item) and that item turning off
    potential_fixes = find(fixationtimes(1,:) >= valid_window(1) & fixationtimes(1,:) < valid_window(2));
    if isempty(potential_fixes)
        disp('No potentail fixation found for this item')
    end
    
    %find valid/potentail fixation inside the fixation window
    iswithin = NaN(1,length(potential_fixes)); %determine if fixation are within fixwin
    dist_from_item = NaN(1,length(potential_fixes)); %determine distance from fixation to item
    for f = 1:length(potential_fixes)
        if fixations(1,potential_fixes(f)) >= item_locations(1,item)-fixwin/2 && ... 
           fixations(1,potential_fixes(f)) <= item_locations(1,item)+fixwin/2 && ...
           fixations(2,potential_fixes(f)) >= item_locations(2,item)-fixwin/2 && ... 
           fixations(2,potential_fixes(f)) <= item_locations(2,item)+fixwin/2
           iswithin(f) = 1;  
        end
        dist_from_item(f) = sqrt((fixations(1,potential_fixes(f))-item_locations(1,item)).^2 ...
        +(fixations(2,potential_fixes(f))-item_locations(2,item)).^2);
    end 
    if ~any(iswithin) %if no fixation found
        if any(dist_from_item < 3) %in case calibration issue which there shouldn't
            %give an extra 0.5 dva
           iswithin(dist_from_item < 3) = 1;
        else
           disp('No Fixations on Item found') 
           %not sure code and calibration is 100% accurate so don't want to
           %call an error
           continue;%go to the next item
        end
    end
    
    %the first fixation in the fixation window is the right one
    the_fixation = find(iswithin == 1);
    fixation_number_on_item(item) = potential_fixes(the_fixation(1));%go back to original index
    fixation_accuracy(item) = dist_from_item(the_fixation(1));
end


last_saccade_was_corrective  = false; %for keeping track of extra fixations parameter
for item = 1:4  
   if item == 1;
        relevant_code_indexes = [find(event_codes == item_on_off_codes(1,item))...
            find(event_codes == item_on_off_codes(2,item))];
    else
        relevant_code_indexes = [find(event_codes == item_on_off_codes(2,item-1))...
            find(event_codes == item_on_off_codes(2,item))];
   end
    relevant_events = event_codes(relevant_code_indexes(1):relevant_code_indexes(2));
    relevant_event_times = event_times(relevant_code_indexes(1):relevant_code_indexes(2))...
        -eye_data_start;%correct for offset from eye data start
    if item == 1
        event_start = relevant_event_times(1);%when item turned on
    else
        event_start = relevant_event_times(2);
        %when item turned on, because 1st event is when last item turned off
    end

    event_end   = relevant_event_times(end);%when item turned off
    
    
    %---Get some information from Cortex Codes---%
    % 1) determine if monkey broke fixation and refixated the item 
    % 2) determine when cortex thought the monkey fixated the item
    % 3) determine if cortex encoded a truly predictive saccade causing the
    % item to appear early or would have (i.e. between 0-50 ms early) 
    cortexfixations = find(relevant_events == fixation_code);
    cortexbreakfixations = find(relevant_events == break_fixation_code);
    
    if ~isempty(cortexbreakfixations)
        broke_fixation = 1;  %to keep track of later in case needed
    else
        broke_fixation = 0;
    end
    
    cortexfixations= relevant_event_times(cortexfixations); %when cortex said eye was within fixation window
    cortexreactiontime = cortexfixations(1)-event_start;%1st 1 in case they refixate
    
    if any(relevant_events == predicted_code) %so triggered item to appear early
        predicted = 1;
    elseif any(relevant_events == started_predicted_code) ... 
            && ~any(relevant_events == broke_predicted_code) && ...
            cortexfixationtime-relevant_event_times(relevant_events == predicted_code) < 50
            % started to trigger next item to appear early but wasn't there 
            % early enough, didn't break fixation on imaginary fixation
            % window to trigger next item, and triggered a fixation code on
            % the next item within 50 ms.
        predicted = 1;
    else
        predicted = 0;
    end
        

    %---determine if next saccade was corrective---%
    if saccadetimes(1,1) < fixationtimes(1,1)%determine if the 1st eye movment is a saccade or a fixation
        saccadeindex = 1;%meaning next saccade is 1 index higher
    else
        saccadeindex = 0;%meaning next saccade is same index
    end
 
    if length(fixations) >= fixation_number_on_item(item)+1%if there is a next fixation
        %and if the next fixation is still in the fixatoin window and the
        if (fixations(1,fixation_number_on_item(item)+1) >= item_locations(1,item)-fixwin/2 && ... 
           fixations(1,fixation_number_on_item(item)+1) <= item_locations(1,item)+fixwin/2 && ...
           fixations(2,fixation_number_on_item(item)+1) >= item_locations(2,item)-fixwin/2 && ... 
           fixations(2,fixation_number_on_item(item)+1) <= item_locations(2,item)+fixwin/2)
           %then we assume there was a corrective saccade or a detected
           %microsaccade since the eye is still in the fixation window
           last_saccade_was_corrective = true; 
        else
           last_saccade_was_corrective = false; 
        end
    else
        last_saccade_was_corrective = false; %so doesn't go to the next iteration 
    end
    
    
    %---Calculate Fixation(s) Duration---%
    %fixation duration for fixation on item (unless made corrective 2 then fixations)
    if isnan(fixation_number_on_item(item)) %aka cluster Fix didn't find fixation
        fixdur = NaN;
    else
        if last_saccade_was_corrective
            fixdur = fixationtimes(2,fixation_number_on_item(item)+1)...
                -fixationtimes(1,fixation_number_on_item(item))+1;
            %this counts corrective or microsaccade too
        else
            fixdur = fixationtimes(2,fixation_number_on_item(item))...
                -fixationtimes(1,fixation_number_on_item(item))+1;
        end
    end
   
    
    %---Get number of extra fixations before fixating item---%
    if item == 1%if this the first item get fixations from when trial strats to fixation on item
        priorfixations = find(fixationtimes(1,:) < event_start);%find all fixations after event started
        priorfixations(priorfixations > fixation_number_on_item(item)) = [];%remove all fixations after the one on the item
        extrafixations = length(priorfixations); %number of no item fixations
    else %if get the number of fixations not on any item
         priorfixations = find(fixationtimes(1,:) > relevant_event_times(1));
         %find all fixations after the last item turned off
         priorfixations(priorfixations > fixation_number_on_item(item)) = [];
         if last_saccade_was_corrective 
             priorfixations = priorfixations-1; %since last fixation was really 2 fixations
         end
         extrafixations = length(priorfixations); %number of no item fixations
    end
       
    
    %---Determine when the saccade leaving the fixation window occured---%
    if fixation_number_on_item(item)+saccadeindex+1 <= size(saccadetimes,2)
        if ~broke_fixation%never broke fixation then refixated
            if last_saccade_was_corrective %then we want the saccade after the corrective saccade
                saccade_start = fixationtimes(2,fixation_number_on_item(item)+1)+1;
            else
                saccade_start = fixationtimes(2,fixation_number_on_item(item))+1;
            end
            time_2_leave = saccade_start-event_end;
            if time_2_leave < 0 %may want to add some additional correcting code later
                disp('Possible error eyes left fixation window before item was turned off?')
            end
        else
            time_2_leave = NaN; %don't really want this value in case it's corrupted by bad behavior
        end
    else
        time_2_leave = NaN;
    end
    
    
    %---Determine the reaction times according to Cluster Fix---%
    if isnan(fixation_number_on_item(item))
        fixationstart = NaN;
        reactiontime = NaN;
    else
        fixationstart = fixationtimes(1,fixation_number_on_item(item)); %when monkey started fixation in fixwin
        reactiontime = fixationstart-event_start;
        if item > 1 && reactiontime > 600
           disp('Too slow') 
        end
    end
    
    %---Store all the data in a single structure array----%
    trialdata.fixationnums(item) =fixation_number_on_item(item);%fixation number associated with each item #
    trialdata.t2f(item) = reactiontime;%time to fixation by item #
    trialdata.accuracy(item) = fixation_accuracy(item);%fixation accuracy by item #
    trialdata.extrafixations(item) = extrafixations;%# of extra fixations by item #
    trialdata.fixation_duration(item) = fixdur;%fixation duraiton by item #
    trialdata.time_to_leave(item) = time_2_leave;%how long after item disapears before a saccade
    trialdata.cortext2f(item) = cortexreactiontime;%time to fixation according to cortex
    trialdata.cortexbreak(item) = broke_fixation;% whether monkey broke then refixated
    trialdata.cortexpredict(item) = predicted;%1's if cortex said truly predictive
    
end
end