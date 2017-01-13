function trialdata = analyze_sequence_trial(fixationstats,item_locations,fixwin,...
    event_codes,event_times,isrecording)
% written by Seth Konig January 25, 2015
% function analyzes sigle trial data from the sequence task. For sucessful
% trials only.
%
% Code rechecked bugs January 3, 2017 SDK

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
%       d) trialdata.fixation_duration: fixation duraiton by item #
%       e) trialdata.cortexpredict: 1's if cortex said truly predictive
%       f) trialdata.cortext2f: time to fixation according to cortex
%       g) trialdata.cortexbreak: whether monkey broke then refixated

if isrecording %then ephiz recording
    valid_start = 501+event_times(1); %500 ms in ITI can start looking for fixatiosn in window
    eye_data_start = event_times(1);%eye data is collected continuously
elseif ~isrecording
    valid_start = 1001;%no eye data before this so can't look into ITI during cortex only sessions
    eye_data_start = 1000;%fixation times already account for this
else
    error('Recording status not stated')
end

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
xy = fixationstats.XY;

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
for item = 1:4
    if item == 1
        valid_window = [valid_start event_times(event_codes == item_on_off_codes(2,item))]-eye_data_start;
    else
        valid_window = [event_times(event_codes == item_on_off_codes(2,item-1))...
            event_times(event_codes == item_on_off_codes(2,item))]-eye_data_start;
    end
    if valid_window(2) > length(xy)+50
        disp('error: probably have an indexing issue')
    end
    
    %find fixations that occur within a time period between the last item
    %on (or trial start if 1st item) and that item turning off
    potential_fixes = find(fixationtimes(1,:) >= valid_window(1) & fixationtimes(1,:) < valid_window(2));
    if isempty(potential_fixes)
        disp('No potential fixation found for this item')
    end
    
    %find valid/potentail fixation inside the fixation window
    iswithin = NaN(1,length(potential_fixes)); %determine if fixation are within fixwin
    dist_from_item = NaN(1,length(potential_fixes)); %determine distance from fixation to item
    for f = 1:length(potential_fixes)
        dist_from_item(f) = sqrt((fixations(1,potential_fixes(f))-item_locations(1,item)).^2 ...
            +(fixations(2,potential_fixes(f))-item_locations(2,item)).^2);
    end
    if any(dist_from_item < fixwin/2+0.5)
        if any(dist_from_item < fixwin/2+0.5) %add 0.5 since square window and
            % using distance (could be up to 2.5*sqrt(2)) but don't want to
            % be too far off either
            iswithin(dist_from_item < fixwin/2+0.5) = 1;
        else
            disp('No Fixations on Item found')
            %not sure code and calibration is 100% accurate so don't want to
            %call an error
            continue;%go to the next item
        end
    end
    
    %the first fixation in the fixation window is the right one
    the_fixation = find(iswithin == 1);
    fixdurs = NaN(1,length(the_fixation));
    for t = 1:length(the_fixation)
        fixdurs(t) = diff(fixationtimes(:,potential_fixes(the_fixation(t))))+1;
        if fixdurs(t) < 500 %not long enough check how much eye data with start of fixation is in window
            w = t; %check if next fixation is still in the window
            while w < length(the_fixation) && ~isnan(iswithin(w+1)) %if still in window
                % then this next fixation duration is added
                fixdurs(t) = fixationtimes(2,potential_fixes(the_fixation(w+1)))-...
                    fixationtimes(1,potential_fixes(the_fixation(t)))+1;
                w = w+1;
            end
        end
    end
    the_fixation(fixdurs < 450) = [];  %slight buffer for fixation window vs fixation detected by Cluster Fix
    if ~isempty(the_fixation)
        trialdata.fixationnums(item) =potential_fixes(the_fixation(1));%go back to original index
        trialdata.accuracy(item) = dist_from_item(the_fixation(1));
        trialdata.fixation_duration(item) = fixdurs(1);%fixation duraiton by item #
    else
        continue;%go to the next item
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%---Get some information from Cortex Codes---%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for item = 1:4
    if item == 1;
        relevant_code_indexes = [1 find(event_codes == item_on_off_codes(2,item))];
    else
        relevant_code_indexes = [find(event_codes == item_on_off_codes(2,item-1))...
            find(event_codes == item_on_off_codes(2,item))];
    end
    relevant_events = event_codes(relevant_code_indexes(1):relevant_code_indexes(2));
    relevant_event_times = event_times(relevant_code_indexes(1):relevant_code_indexes(2))...
        -eye_data_start;%correct for offset from eye data start
    item_on =  event_times(event_codes == item_on_off_codes(1,item))-eye_data_start; %when item turned on
    

    %Did Cortex Record a break fixation on item
    cortexbreakfixations = find(relevant_events == break_fixation_code);
    if ~isempty(cortexbreakfixations)
        trialdata.cortexbreak(item) = 1;% whether monkey broke then refixated
    else
        trialdata.cortexbreak(item) = 0;% whether monkey broke then refixated
    end
    
    %Reaction time According to Cortex
    cortexfixations = find(relevant_events == fixation_code);
    cortexfixations= relevant_event_times(cortexfixations); %when cortex said eye was within fixation window
    cortexreactiontime = cortexfixations(1)-item_on;%1st 1 in case they refixate
    trialdata.cortext2f(item) = cortexreactiontime;%time to fixation according to cortex
    
    %Determine if Cortex Recorded a predictive fixation
    if any(relevant_events == predicted_code) %so triggered item to appear early
        trialdata.cortexpredict(item) = 1;
    elseif any(relevant_events == started_predicted_code) ...
            && ~any(relevant_events == broke_predicted_code) && ...
            cortexfixationtime-relevant_event_times(relevant_events == predicted_code) < 50
        % started to trigger next item to appear early but wasn't there
        % early enough, didn't break fixation on imaginary fixation
        % window, and triggered a fixation code on the next item within 50 ms.
        trialdata.cortexpredict(item) = 1;
    else
        trialdata.cortexpredict(item) = 0;
    end
    
    %---Determine the reaction times according to Cluster Fix---%
    if isnan(trialdata.fixationnums(item))
        trialdata.t2f(item) = NaN;
    else
        fixationstart = fixationtimes(1,trialdata.fixationnums(item)); %when monkey started fixation in fixwin
        trialdata.t2f(item) = fixationstart-item_on;
    end
end
end