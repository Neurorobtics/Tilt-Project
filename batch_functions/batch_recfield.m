function [] = batch_recfield(project_path, save_path, failed_path, data_path, dir_name, filename_substring_one, config)
    rf_start = tic;
    config_log = config;
    file_list = get_file_list(data_path, '.mat');
    file_list = update_file_list(file_list, failed_path, config.include_sessions);

    %% Pull variable names into workspace scope for log
    pre_time = config.pre_time; pre_start = config.pre_start; pre_end = config.pre_end;
    post_time = config.post_time; post_start = config.post_start; post_end = config.post_end;
    bin_size = config.bin_size; threshold_scalar = config.threshold_scalar;
    sig_check = config.sig_check; consec_bins = config.consec_bins; span = config.span;
    sig_alpha = config.cell_sig_alpha;
    cluster_analysis = config.cluster_analysis; bin_gap = config.bin_gap;
    unsmoothed_recfield_metrics = config.unsmoothed_recfield_metrics;

    meta_headers = {'filename', 'animal_id', 'exp_group', 'exp_condition', ...
        'optional_info', 'date', 'record_session', 'pre_time', ...
        'pre_start', 'pre_end', 'post_time', 'post_start', 'post_end', 'bin_size', ...
        'sig_alpha', 'unsmoothed_recfield_metrics', 'sig_check', 'consec_bins', ...
        'span', 'threshold_scalar', 'cluster_analysis', 'bin_gap'};
    ignore_headers = {
        'significant', 'background_rate', 'background_std', 'threshold', 'p_val', ...
        'first_latency', 'last_latency', 'duration', 'peak_latency', 'peak_response', ...
        'corrected_peak', 'response_magnitude', 'corrected_response_magnitude', ...
        'total_sig_events', 'principal_event', 'norm_response_magnitude', 'recording_notes', ...
        'tot_clusters', 'first_cluster_first_latency', 'first_cluster_last_latency', ...
        'first_cluster_duration', 'first_cluster_peak_latency', 'first_cluster_peak_response', ...
        'first_cluster_corrected_peak', 'first_cluster_response_magnitude', ...
        'first_cluster_corrected_response_magnitude', 'first_cluster_norm_response_magnitude', ...
        'primary_cluster_first_latency', 'primary_cluster_last_latency', ...
        'primary_cluster_duration', 'primary_cluster_peak_latency', ...
        'primary_cluster_peak_response', 'primary_cluster_corrected_peak', ...
        'primary_cluster_response_magnitude', 'primary_cluster_corrected_response_magnitude', ...
        'primary_cluster_norm_response_magnitude', 'last_cluster_first_latency', ...
        'last_cluster_last_latency', 'last_cluster_duration', 'last_cluster_peak_latency', ...
        'last_cluster_peak_response', 'last_cluster_corrected_peak', ...
        'last_cluster_response_magnitude', 'last_cluster_corrected_response_magnitude', ...
        'last_cluster_norm_response_magnitude'
    };
    analysis_headers = [{'region'}, {'sig_channels'}, {'user_channels'}, ...
        {'event'}, ignore_headers];

    sprintf('Receptive field analysis for %s \n', dir_name);
    all_neurons = [];
    general_info = table;
    for file_index = 1:length(file_list)
        try
            %% pull info from filename and set up file path for analysis
            file = fullfile(data_path, file_list(file_index).name);

            %% Load needed variables from psth and does the receptive field analysis
            load(file, 'psth_struct', 'label_log', 'filename_meta');
            %% Check psth variables to make sure they are not empty
            %TODO add check to make sure there is baseline and response window

            [sig_neurons, non_sig_neurons, cluster_struct] = receptive_field_analysis( ...
                label_log, psth_struct, bin_size, pre_time, pre_start, ...
                pre_end, post_start, post_end, span, threshold_scalar, ...
                sig_check, sig_alpha, consec_bins, ...
                unsmoothed_recfield_metrics, cluster_analysis, bin_gap, ...
                analysis_headers);

            %% Capture data to save to csv from current day
            session_neurons = [sig_neurons; non_sig_neurons];
            current_general_info = [
                {filename_meta.filename}, {filename_meta.animal_id}, ...
                {filename_meta.experimental_group}, ...
                {filename_meta.experimental_condition}, ...
                {filename_meta.optional_info}, filename_meta.session_date, ...
                filename_meta.session_num, pre_time, pre_start, ...
                pre_end, post_time, post_start, post_end, bin_size, ...
                sig_alpha, unsmoothed_recfield_metrics, ...
                sig_check, consec_bins, span, threshold_scalar, ...
                cluster_analysis, bin_gap];
            [general_info, all_neurons] = ...
                concat_tables(meta_headers, general_info, current_general_info, all_neurons, session_neurons);

            %% Save receptive field matlab output
            % Does not check if variables are empty since there may/may not be significant responses in a set
            matfile = fullfile(save_path, ['rec_field_', filename_meta.filename, '.mat']);
            save(matfile, 'label_log', 'sig_neurons', 'non_sig_neurons', 'filename_meta', 'config_log', 'cluster_struct');
        catch ME
            handle_ME(ME, failed_path, filename_meta.filename);
        end
    end

    %% CSV export set up
    rf_results = [general_info, all_neurons];
    % remove p value from receptive field csv
    rf_results = removevars(rf_results, 'p_val');
    csv_path = fullfile(project_path, [filename_substring_one, '_receptive_field_results.csv']);
    export_csv(csv_path, rf_results, ignore_headers);

    fprintf('Finished receptive field analysis for %s. It took %s \n', ...
        dir_name, num2str(toc(rf_start)));
end