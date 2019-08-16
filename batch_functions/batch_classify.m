function [] = batch_classify(animal_name, original_path, data_path, dir_name, ...
        search_ext, filename_substring_one, filename_substring_two, ...
        config)
    classifier_start = tic;

    %% Classifier set up
    [files, classify_path, failed_path] = create_dir(data_path, dir_name, search_ext);
    export_params(classify_path, 'classifier', failed_path, ...
        animal_name, config);

    general_column_names = {'animal', 'group', 'date', 'record_session', 'bin_size', 'pre_time', ...
        'post_time', 'bootstrap_classifier', 'boot_iterations'};
    analysis_column_names = {'region', 'channel', 'performance', 'mutual_info', ...
        'boot_info', 'corrected_info', 'synergy_redundancy', 'synergistic', 'notes'};
    column_names = [general_column_names, analysis_column_names];

    sprintf('PSTH classification for %s \n', animal_name);

    pop_config_info = table;
    unit_config_info = table;
    pop_info = [];
    unit_info = [];
    for file_index = 1:length(files)
        %% Run through files
        try
            %% pull info from filename and set up file path for analysis
            file = fullfile(data_path, files(file_index).name);
            [~, filename, ~] = fileparts(file);
            filename = erase(filename, [filename_substring_one, '.', filename_substring_two, '.']);
            filename = erase(filename, [filename_substring_one, '_', filename_substring_two, '_']);
            [~, experimental_group, ~, session_num, session_date, ~] = get_filename_info(filename);
            load(file, 'labeled_data', 'psth_struct', 'event_ts', 'response_window');
            %% Check psth variables to make sure they are not empty
            empty_vars = check_variables(file, psth_struct, labeled_data, event_ts, response_window);
            if empty_vars
                continue
            end

            %% Classify and bootstrap
            [unit_struct, pop_struct, pop_table, unit_table] = psth_bootstrapper( ...
                labeled_data, psth_struct, response_window, event_ts, ...
                config.boot_iterations, config.bootstrap_classifier, config.bin_size, ...
                config.pre_time, config.pre_start, config.pre_end, config.post_time, ...
                config.post_start, config.post_end, analysis_column_names);

            %% PSTH synergy redundancy
            [pop_table] = synergy_redundancy(pop_table, unit_table, config.bootstrap_classifier);

            current_general_info = [{animal_name}, {experimental_group}, session_date, session_num, ...
                config.bin_size, config.pre_time, config.post_time, config.bootstrap_classifier, ...
                config.boot_iterations];
            [pop_config_info, pop_info] = ...
                concat_tables(general_column_names, pop_config_info, current_general_info, pop_info, pop_table);
            [unit_config_info, unit_info] = ...
                concat_tables(general_column_names, unit_config_info, current_general_info, unit_info, unit_table);

            matfile = fullfile(classify_path, ['test_psth_classifier_', filename, '.mat']);
            check_variables(matfile, psth_struct, unit_struct, pop_struct, pop_table, unit_table);
            save(matfile, 'pop_struct', 'unit_struct', 'pop_table', 'unit_table');
        catch ME
            handle_ME(ME, failed_path, filename);
        end
    end

    %% CSV set up
    unit_csv_path = fullfile(original_path, ['unit_', filename_substring_one, '_classification_info.csv']);
    pop_csv_path = fullfile(original_path, ['pop_', filename_substring_one, '_classification_info.csv']);
    export_csv(unit_csv_path, column_names, unit_config_info, unit_info);
    export_csv(pop_csv_path, column_names, pop_config_info, pop_info);

    fprintf('Finished PSTH classifier for %s. It took %s \n', ...
        animal_name, num2str(toc(classifier_start)));
end