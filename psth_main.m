function [] = psth_main()
    %% Get directory with all animals and their data
    original_path = uigetdir(pwd);
    start_time = tic;
    animal_list = dir(original_path);
    animal_names = {animal_list([animal_list.isdir] == 1 & ~contains({animal_list.name}, '.')).name};
    for animal = 1:length(animal_names)
        animal_name = animal_names{animal};
        animal_path = fullfile(...
            animal_list(strcmpi(animal_names{animal}, {animal_list.name})).folder, animal_name);
        config = import_config(animal_path, 'psth');
        check_time(config.pre_time, config.pre_start, config.pre_end, config.post_time, ...
            config.post_start, config.post_end, config.bin_size);
        export_params(animal_path, 'main', config);
        % Skips animals we want to ignore
        if config.ignore_animal
            continue;
        else
            %% Checks to see if parsed directory exists
            parsed_path = [animal_path, '/', 'parsed'];
            if ~exist(parsed_path, 'dir')
                error('Parsed directory does not exist. Please run the Parser main to parse files');
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%        Format PSTH         %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if config.create_psth
                psth_path = batch_format_psth(animal_path, parsed_path, animal_name, config);
            else
                psth_path = [parsed_path, '/psth'];
            end

            if config.update_psth_windows
                failed_path = [psth_path, '/failed_', 'window_slice'];
                if exist(failed_path, 'dir') == 7
                    delete([failed_path, '/*']);
                    rmdir(failed_path);
                end
                file_list = get_file_list(psth_path, '.mat', config.ignore_sessions);
                for file_index = 1:length(file_list)
                    try
                        %% pull info from filename and set up file path for analysis
                        file = fullfile(psth_path, file_list(file_index).name);
                        [~, filename, ~] = fileparts(file);

                        %% Load needed variables from psth and does the receptive field analysis
                        load(file, 'selected_data', 'psth_struct');
                        %% Check psth variables to make sure they are not empty
                        empty_vars = check_variables(file, selected_data, psth_struct);
                        if empty_vars
                            continue
                        end

                        %% Add analysis window
                        [baseline_window, response_window] = create_analysis_windows(selected_data, psth_struct, ...
                            config.pre_time, config.pre_start, config.pre_end, config.post_time, ...
                            config.post_start, config.post_end, config.bin_size);

                        %% Saving outputs
                        matfile = fullfile(psth_path, [filename, '.mat']);
                        %% Check PSTH output to make sure there are no issues with the output
                        empty_vars = check_variables(matfile, psth_struct, selected_data, baseline_window, response_window);
                        if empty_vars
                            continue
                        end
                        %% Save file if all variables are not empty
                        save(matfile, 'baseline_window', 'response_window', '-append');
                    catch ME
                        handle_ME(ME, failed_path, filename);
                    end
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%  Receptive Field Analysis  %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if config.rf_analysis
                rf_path = batch_recfield(animal_name, original_path, psth_path, ...
                    'receptive_field_analysis', '.mat', 'PSTH', config);
            else
                rf_path = [psth_path, '/receptive_field_analysis'];
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%         Graph PSTH         %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if config.make_psth_graphs
                batch_graph(animal_name, psth_path, 'psth_graphs', '.mat', config, rf_path);
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%     Normalized Variance    %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if config.nv_analysis
                batch_nv(animal_name, original_path, psth_path, ...
                    'normalized_variance_analysis', '.mat', 'psth', config)
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%     PSTH Classification    %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if config.psth_classify
                batch_classify(animal_name, original_path, psth_path, ...
                    'classifier', '.mat', 'PSTH', config);
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %    Information Analysis    %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if config.info_analysis
                batch_info(animal_name, psth_path, 'mutual_info', ...
                    '.mat', config.ignore_sessions);
            end
        end
    end
    toc(start_time);
end