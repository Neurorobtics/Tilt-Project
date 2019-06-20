function [pca_struct, all_events, event_ts] = create_pca_input(labeled_neurons, event_ts,  ...
        event_window, wanted_events, trial_range, trial_lower_bound)

    tot_bins = length(event_window) - 1;
    %% Organize and group timestamps
    [~, all_events, event_ts] = organize_events(event_ts, ...
        trial_lower_bound, trial_range, wanted_events);
    %% Organize event_ts to be in chronological order by event label
    event_ts = sort(event_ts);
    tot_trials = length(event_ts(:, 1));

    pca_struct = struct;

    unique_regions = fieldnames(labeled_neurons);
    for region_index = 1:length(unique_regions)
        region = unique_regions{region_index};
        region_neurons = [labeled_neurons.(region)(:,1), labeled_neurons.(region)(:,4)];
        [tot_region_neurons, ~] = size(region_neurons);
        region_pca_input = nan((tot_bins * tot_trials), tot_region_neurons);
        for neuron_index = 1:tot_region_neurons
            neuron_ts = region_neurons{neuron_index, 2};
            neuron_response = nan((tot_bins * tot_trials), 1);
            trial_start = 1;
            trial_end = tot_bins;
            for trial_index = 1:tot_trials
                trial_ts = event_ts(trial_index, 2);
                offset_ts = neuron_ts - trial_ts * ones(size(neuron_ts));
                [offset_response, ~] = histcounts(offset_ts, event_window);
                neuron_response(trial_start:trial_end) = offset_response;
                trial_start = trial_start + tot_bins;
                trial_end = trial_end + tot_bins;
            end
            region_pca_input(:, neuron_index) = neuron_response;
        end
        z_region_pca_input = zscore(region_pca_input);
        pca_struct.(region).region_pca_input = region_pca_input;
        pca_struct.(region).z_region_pca_input = z_region_pca_input;
    end
end