clar

task = 'ListSQ';
set(0,'DefaultFigureVisible','OFF');
for monkey = 2:-1:1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %---Read in Excel Sheet for Session data---%%%
    %only need to run when somethings changed or sessions have been added
    if monkey == 1%strcmpi(monkey,'Vivian')
        excel_dir = '\\towerexablox.wanprc.org\Buffalo\eblab\PLX files\Vivian\';
        excel_file = [excel_dir 'Vivian_Recording_Notes-ListSQ.xlsx']; %recording notes
        data_dir = 'C:\Users\seth.koenig\Documents\MATLAB\ListSQ\PW Resorted\';
        figure_dir = 'C:\Users\seth.koenig\Documents\MATLAB\ListSQ\PW Resorted Figures\';
        
        listsq_read_excel(data_dir,excel_file);
        load([data_dir 'Across_Session_Unit_Data_Vivian.mat'])
        
        predict_rt = 155;%155.85 ms prediction 5-percentile
        chamber_zero = [13.5 -11]; %AP ML
        
    elseif monkey ==2%strcmpi(monkey,'Tobii')
        excel_dir = '\\towerexablox.wanprc.org\Buffalo\eblab\PLX files\Tobii\';
        excel_file = [excel_dir 'Tobii_recordingnotes.xlsx']; %recording notes
        data_dir = 'C:\Users\seth.koenig\Documents\MATLAB\ListSQ\TO Recording Files\';
        figure_dir = 'C:\Users\seth.koenig\Documents\MATLAB\ListSQ\TO Figures\';
        
        predict_rt = 135;%ms prediction 5-percentile
        chamber_zero = [7.5 15]; %AP ML, his posertior hippocampus appears slightly shorter/more compressed than atlas
        
        listsq_read_excel(data_dir,excel_file);
        load([data_dir 'Across_Session_Unit_Data_Tobii.mat'])
        session_data(end) = [];%last file doesn't have strobe signal working so have no timing singnal :(
    end
    
    for sess = 1:length(session_data)
        
        task = 'ListSQ';
        colors ='rgbm';
        shapes = 'xo';
        
        imageX = 800;
        imageY = 600;
        img_on_code = 23; %cortex code when image turns on
        img_off_code = 24; %cortex code when image turns off
        ITIstart_code = 15; %start of ITI/trial
        event_codes = [23 24 25 26 27 28 29 30]; %Sequence task: odd indeces item on, even indeces item off
        numshuffs = 10000; %number of shuffles for resmampling
        
        min_fix_dur = 100; %100 ms %don't want fixations that are too short since won't get a good idea of firing pattern
        min_sac_amp = 48;%48 pixels = 2 dva don't want mini/micro saccades too small and hard to detect
        
        Fs = 1000; %Hz sampling frequency
        fixwin = 5;%size of fixation window on each crosshair
        smval = 30;%2*std of gaussian kernel so 15 ms standard deviation
        min_blks = 2; %only analyzes units with at least 2 novel/repeat blocks (any block/parts of blocks)
        twin1 = 200;%200 ms before fixation
        twin2 = 400;%400 ms after start of fixation
        image_on_twin = 500;%how much time to ignore eye movements for to remove strong visual response though some may last longer
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%---import task and unit data---%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        task_file = get_task_data(session_data{sess},task);
        if isempty(task_file)
            warning('No file could be found for specificed task. Exiting function...')
            return
        end
        try
            load([data_dir task_file(1:end-11) '-spatial_analysis_results.mat']);
        catch
            disp('Spatial Analysis File not found continueing')
            return
        end
        load([data_dir task_file(1:end-11) '-preprocessed.mat']);
        
        %Save as new variableso can reload later...kind of dumb but that was how it was written
        absolute_fixationstats = fixationstats;
        absolute_cfg = cfg;
        
        [task_file,item_file,cnd_file,multiunit,unit_names,unit_confidence,sorting_quality,~]...
            = get_task_data(session_data{sess},task);
        [multiunit,unit_stats,num_units] = get_unit_names(cfg,hdr,data,unit_names,...
            multiunit,unit_confidence,sorting_quality);
        clear unit_names
        
        if num_units == 0; %if no units exit function
            disp([task_file(1:8) ': no units could be found. Exiting function...'])
            return;
        end
        
        valid_trials = determine_valid_trials(task_file,valid_trials,cfg,num_units,min_blks,task);
        if all(isnan(valid_trials(1,:)))
            disp([task_file(1:8) ': no valid units could be found. Exiting function...'])
            return %since no valid units skip analysis
        end
        
        %remove units with too few trials
        %these are the absolute minimum data required to do data analysis
        %set the image duration
        if str2double(task_file(3:8)) < 140805
            imgdur = 7000;
        else
            imgdur = 5000;
        end
        
        %get important task specific information
        [itmlist,sequence_items,sequence_locations] = read_ListSQ_itm_and_cnd_files(item_file,cnd_file);
        [which_img,~,img_cnd] = get_image_numbers(cfg,itmlist,sequence_items,img_on_code);
        
        %filter parameters
        H = define_spatial_filter(filter_width);
        
        %---Pre-allocate space for List Fixations Inside vs Outside Field Analysis---%
        list_fixation_locked_firing = cell(1,num_units); %firing rate locked to fixations
        saccade_direction = cell(1,num_units); %saccade direction organized the same as list_fixation_locked_firing
        saccade_amplitude = cell(1,num_units); %saccade direction organized the same as list_fixation_locked_firing
        area = NaN(1,num_units); %area of place field
        all_place_field_matrix = cell(1,num_units); %place field location 1 for in 0 for out, NaN for no coverage
        list_sig_times = cell(2,num_units); %%time points > 95% confidence interval, corrected for multiple comparisons using Maris method
        in_out = cell(1,num_units); %organized same as list_fixation_locked_firing for fixations ....
        %1) first fixation in: out-> in
        %2) fixation in field but not first: in -> in
        %3) first fixation out of field: in -> out
        %4) fixation out of field but not first: out-> out
        
        %---Pre-allocate space for Fixations during Sequence Trials Analysis---%
        sequence_fixation_locked_firing = cell(4,num_units);%firing rate locked to fixations organized by item
        sequence_sig_times = cell(2,num_units);  %shuffled 95% confidence interval for fixation in field vs out of field, row 1 97.5% row 2 2.5%
        sequence_sig_times = cell(1,num_units);%time points > 95% confidence interval
        all_which_sequence = cell(1,num_units); %which sequence
        trial_nums = cell(1,num_units); %trial numbers
        in_out_sequence = cell(1,num_units); %1 for sequence items inside 0 for suquence items outside NaN for items on border
        
        stats_across_tasks = NaN(4,num_units);
        %1) list peak location
        %2) list peak
        %3) sequence peak location
        %4) sequence peak
        
        for unit = 1:num_units
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%---Determine if Unit Passes 95% for both Skaggs and Stability--%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if isnan(spatial_info.shuffled_rate_prctile(unit))
                continue %spatial analysis wasn't run on this unit
                %     elseif (spatial_info.shuffled_rate_prctile(unit) < 95) && (spatial_info.spatialstability_halves_prctile(unit) < 95)
                %         continue %unit not spatial or correlated in any sense
            end
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%---Determine List Firing rate Locked to Fixations Inside vs Outside Field---%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%---Calculate Firing Rate Map---%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            firing_rate_map = get_firing_rate_map({eyepos{unit},spike_times{unit}},imageX,imageY,binsize,H,Fs,'all'); %get firing rate map
            place_field_matrix = define_place_field(firing_rate_map,imageX,imageY); %place field location
            all_place_field_matrix{unit} = place_field_matrix; %save place field location
            area(unit) = 100*nansum(nansum(place_field_matrix))/(imageX*imageY); %calculate area as % of screen size
            %note ignores incomplete coverage
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%---Calculate Firing Rate Locked to Fixations---%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            fix_in_out = NaN(1,3000); %firing rate for fixations inside or outside  of place field
            %1) first fixation in: out-> in
            %2) fixation in field but not first: in -> in
            %3) first fixation out of field: in -> out
            %4) fixation out of field but not first: out-> out
            fix_locked_firing = NaN(3000,(twin1+twin2)); %spike trains locked to fixations
            
            fix_ind = 1; %fixation # so can track in variables above
            fixationstats = absolute_fixationstats; %reload because written over below
            cfg = absolute_cfg; %reload because written over below
            num_trials = length(cfg.trl);%number of trials
            for t = 1:num_trials
                if t >= valid_trials(1,unit) && t <= valid_trials(2,unit) %only valid trials for this unit
                    if any(cfg.trl(t).allval == img_on_code) && itmlist(cfg.trl(t).cnd-1000) > sequence_items(end) %only want image trials
                        trial_start = cfg.trl(t).alltim(cfg.trl(t).allval == ITIstart_code);
                        imgon =  cfg.trl(t).alltim(cfg.trl(t).allval == img_on_code)-trial_start; %when image turns on
                        imgoff = cfg.trl(t).alltim(cfg.trl(t).allval == img_off_code)-trial_start; %when image turns off
                        
                        % if monkey isn't paying attention and looked away image presentation
                        % is now longer than imgdur (because of cumulative looking time)
                        % so data isn't probably worth much plus have to cut off somewhere
                        if imgoff-imgon > 1.5*imgdur-1 %cut off trial at 1.5x length of desired looking time
                            imgoff = imgon+1.5*imgdur-1;
                        end
                        imgon = imgon+image_on_twin; %to avoid visual response and strong central bias
                        
                        fixationtimes = fixationstats{t}.fixationtimes; %fixation start and end times
                        saccadetimes = fixationstats{t}.saccadetimes; %saccade start and end times
                        fixations = round(fixationstats{t}.fixations); %mean fixation location
                        xy = fixationstats{t}.XY; %xy eye trace
                        
                        %find fiations and saccades that did not occur during the image period;
                        %should also take care of the 1st fixation on the crosshair
                        
                        %fixation started before image turned on
                        invalid= find(fixationtimes(1,:) < imgon);
                        fixationtimes(:,invalid) = [];
                        fixations(:,invalid) = [];
                        
                        %fixation started after the image turned off and/or firing rate could corrupted by image turning off
                        invalid= find(fixationtimes(1,:) > imgoff-twin2);
                        fixationtimes(:,invalid) = [];
                        fixations(:,invalid) = [];
                        
                        %saccade started before image turned on
                        invalid= find(saccadetimes(1,:) < imgon);
                        saccadetimes(:,invalid) = [];
                        
                        %saccade started after the image turned off and/or firing rate could corrupted by image turning off
                        invalid= find(saccadetimes(1,:) > imgoff-twin2);
                        saccadetimes(:,invalid) = [];
                        
                        %remove fixations that are too short to really look at for analysis
                        fixdur = fixationtimes(2,:)-fixationtimes(1,:)+1;
                        fixationtimes(:,fixdur < min_fix_dur) = [];
                        fixations(:,fixdur < min_fix_dur) = [];
                        
                        img_index = find(img_cnd == cfg.trl(t).cnd);
                        %which image monkey viewed if nan or empty then skip cuz
                        %bad trial
                        if isempty(img_index) || any(isnan(which_img(img_index)))
                            continue
                        end
                        
                        spikes = find(data(unit).values{t}); %spike trains for this trial
                        for f = 2:size(fixations,2)%ignore first fixation not sure where it was/possibly contaminated anyway
                            prior_sac = find(saccadetimes(2,:) == fixationtimes(1,f)-1);%next fixation should start immediately after
                            if isempty(prior_sac) %no prior saccade so was proabbly looking off screen
                                continue;
                            end
                            sacamp = sqrt(sum((xy(:,saccadetimes(2,prior_sac))-xy(:,saccadetimes(1,prior_sac))).^2)); %saccade amplitude
                            if sacamp < min_sac_amp %prior saccade is too small so ignore
                                continue
                            end
                            saccade_amplitude{unit}(fix_ind) = sacamp;
                            
                            prior_fix_in_out = [];
                            %determine if prior fixation was in or out of place field
                            fixx = fixations(1,f-1);
                            fixx(fixx < 1) = 1;
                            fixx(fixx > imageX) = imageX;
                            fixy = imageY-fixations(2,f-1);
                            fixy(fixy < 1) = 1;
                            fixy(fixy > imageY) = imageY;
                            
                            if place_field_matrix(fixy,fixx) == 1 %then prior fixation was already inside
                                prior_fix_in_out = 1;
                            else
                                prior_fix_in_out = 0;
                            end
                            last_fixx = fixx;
                            last_fixy = fixy;
                            
                            %determine if this fixation was in our out of place field
                            fixx = fixations(1,f);
                            fixx(fixx < 1) = 1;
                            fixx(fixx > imageX) = imageX;
                            fixy = imageY-fixations(2,f);
                            fixy(fixy < 1) = 1;
                            fixy(fixy > imageY) = imageY;
                            if place_field_matrix(fixy,fixx) == 1 %then inside
                                if prior_fix_in_out == 1%prior fixation was inside so in->in
                                    fix_in_out(fix_ind) = 2;
                                else %out->in
                                    fix_in_out(fix_ind) = 1;
                                end
                            elseif place_field_matrix(fixy,fixx) == 0 %then inside, NaNs are for locations not analyzed
                                if prior_fix_in_out == 1%prior fixation was inside so in->out
                                    fix_in_out(fix_ind) = 3;
                                else %out->out
                                    fix_in_out(fix_ind) = 4;
                                end
                            else %not a valid fixation location too sparse of coverage to analyze
                                continue
                            end
                            
                            %get firing rate locked to fixation
                            fixt = fixationtimes(1,f);%start of fixation
                            fix_spikes = spikes(spikes > fixt-twin1 & spikes <= fixt+twin2)-fixt+twin1;
                            temp = zeros(1,twin1+twin2);
                            temp(fix_spikes) = 1;
                            fix_locked_firing(fix_ind,:) = temp;
                            
                            %reflix y otherwise everything is flipped
                            fixy = fixations(2,f);
                            last_fixy = fixations(2,f-1);
                            saccade_direction{unit}(fix_ind) = atan2d(fixy-last_fixy,fixx-last_fixx);
                            
                            fix_ind = fix_ind+1;
                        end
                    end
                end
            end
            
            %remove excess NaNs associated with error trials
            fix_in_out = laundry(fix_in_out);
            fix_locked_firing = laundry(fix_locked_firing);
            
            %store variables across units for later access
            list_fixation_locked_firing{unit} = fix_locked_firing;
            in_out{unit} = fix_in_out;
            saccade_direction = laundry(saccade_direction);
            
            
        end
        
        save([data_dir task_file(1:8) '-Place_Cell_Analysis.mat'],'saccade_amplitude','-append')
    end
end