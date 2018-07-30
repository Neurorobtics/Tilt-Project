function [parsed_path] = parser(dir_path, animal_name, total_trials, total_events)
    tic;
    failed_parsing = {};
    %% Select Directory for debugging purposes
    % dir_path = uigetdir(pwd);
    
    % Necessary for plx_info to run correctly (if the path does not end
    % with / when called in that function, it causes the program to crash)
    original_path = strcat(dir_path, '/');
    
    % Creates a list of all the files in the given directory ending with
    % *.plx
    num_plx = strcat(dir_path, '/*.plx');
    files = dir(num_plx);
    
    % Create parsed directory if it does not already exist    
    parsed_path = strcat(dir_path, '/parsed_plx');
    if ~exist(parsed_path, 'dir')
       mkdir(dir_path, 'parsed_plx');
    end
    
    % Runs through all of the .plx files in the selected directory
    for h = 1: length(files)
        filename = files(h).name;
        seperated_file_name = strsplit(filename, '.');
        current_day = seperated_file_name{4};
        % Take the spike times and event times
        try
            datafile = [original_path, filename];
            [tscounts, wfcounts, evcounts, slowcounts] = plx_info(datafile,1);
            fprintf('Parsing for %s on %s\n', animal_name, current_day);
            
            [nunits1, nchannels1] = size(tscounts); 
            % Allocate memory to all_neurons
            all_neurons = cell(nunits1, nchannels1);
            for iunit = 0:nunits1 - 1   % starting with unit 0 (unsorted) 
                for ich = 1:nchannels1 - 1
                    if (tscounts( iunit+1 , ich+1 ) > 0)
                        % get the timestamps for this channel and unit 
                        [nts, all_neurons{iunit+1,ich}] = plx_ts(datafile, ich , iunit);
                    end
                end
            end
            % Create array for all spikes
            all_spikes = (all_neurons(~cellfun('isempty',all_neurons)))';
            total_neurons = length(all_spikes);
            % All Spikes
            all_spike_times = [];
            for i = 1:length(all_spikes)
                for j = 1:length(all_spikes{1,i})
                    all_spike_times(i,j) = all_spikes{1,i}(j);
                end
            end

            svStrobed = [];
            svdummy = [];
            % and finally the events
            [u, nevchannels] = size( evcounts );
            if (nevchannels > 0) 
                % need the event chanmap to make any sense of these
                [u,evchans] = plx_event_chanmap(datafile);
                for iev = 1:nevchannels
                    if (evcounts(iev) > 0)
                        evch = evchans(iev);
                        if (evch == 257)
                            [nevs{iev}, tsevs{iev}, svStrobed] = plx_event_ts(datafile, evch); 
                        else
                            [nevs{iev}, tsevs{iev}, svdummy{iev}] = plx_event_ts(datafile, evch);
                        end
                    end
                end
            end

            events=[];
            j = 0;
            %% Handles strobbed events
            if length(svStrobed) > 1
                events = tsevs{1, 17};
                events = [svStrobed,events];
            %% Handles nonstrobbed events
            else
                for i=1:length(evcounts)
                    if evcounts(i) >= total_trials
                        [nevs{i}, tsevs{i}, ~] = plx_event_ts(datafile, i);
                        j = j + 1;
                        eventsingle(1:evcounts(i), 1) = j;
                        events= [events;eventsingle, tsevs{i}];
                        eventsingle=[];
                    end
                end
                % TODO potentially use struct solution in calculate_PSTH to relieve hard coding
                for i=1:length(events)
                    if events(i,1) == 2
                        events(i,1) = 3;
                    elseif events(i,1) == 3
                        events(i,1) = 4;
                    elseif events(i,1) == 4
                        events(i,1) = 6;
                    end
                end
            end
            %% Removes Doubles and Triples from events
            [events_rows, ~] = size(events);
            count = 1;
            while events_rows > (total_trials * total_events)
                i = 1;                
                while i <= (length(events)-1)
                    if ((events(i, 2) + 2) > events(i+1, 2))
                        events(i + 1,:) = [];
                    end
                    i = i + 1;
                end
                [events_rows, ~] = size(events);
                if count > 15
                    warning('Potential infinite loop in %s, when trying to remove duplicate events.', ...
                        'Check to make sure that the total events is greater than the standard total', ...
                        'trials * total events');
                    break;
                end
                count = count + 1;
            end
            
            % Sorts nonstrobbed events. This used to be done before removing
            % duplicates, but then it caused infinite loops in some nonstrobbed
            % animals.
            % TODO figure out why that happens.
            if length(svStrobed) < 1
                events = sortrows(events, 2);
            end
            
            %% Create neuron map
            time_stamp_copy = tscounts;
            time_stamp_copy(1,:) = [];
            neuron_map = {};
            [~,spk_names] = plx_chan_names(datafile);
            subchan = ['a','b','c','d'];  
            for i = 1:length(time_stamp_copy)
                p = find(time_stamp_copy(:,i));
                if length(p)>=1
                    for j = 1:length(p)
                        neuron_map(end+1,1) = cellstr([spk_names(i-1,:),subchan(p(j))]);
                    end
                end
            end
            neuron_map = [neuron_map, all_spikes'];
            
            fprintf('Finished parsing for %s\n', current_day);
            %% Saves parsed files
            filename = replace(filename, '.plx', '.mat');
            matfile = fullfile(parsed_path, filename);
            save(matfile, 'tscounts', 'evcounts', 'tsevs', 'events',  ...
                    'total_neurons', 'all_spike_times', 'neuron_map');
        catch
            failed_parsing{end + 1} = filename;
            filename = replace(filename, '.plx', '.mat');
            filename = ['FAILED.', filename];
            warning('%s failed to parse', filename);
            matfile = fullfile(parsed_path, filename);
            save(matfile, failed_parsing);
        end
    end
    toc;
end