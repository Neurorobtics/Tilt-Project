function [] = batch_power_mnts_to_psth(save_path, failed_path, data_path, ...
    dir_name, filename_substring_one, dir_config)

    config_log = dir_config;
    file_list = get_file_list(data_path, '.mat');
    file_list = update_file_list(file_list, failed_path, dir_config.include_sessions);

    for file_index = 1:length(file_list)
        [~, filename, ~] = fileparts(file_list(file_index).name);
        filename_meta.filename = filename;
        try
            %% pull info from filename and set up file path for analysis
            file = fullfile(data_path, file_list(file_index).name);

            %% Load needed variables from psth and does the receptive field analysis
            load(file, 'component_results', ...
                'filename_meta', 'label_log', 'pc_log');
            %% Check psth variables to make sure they are not empty
            empty_vars = check_variables(file, component_results);
            if empty_vars
                continue
            end

            psth_struct = struct;
            unique_powers = fieldnames(pc_log);
            for power_i = 1:length(unique_powers)
                bandname = unique_powers{power_i};
                %TODO add back baseline and response structs if necessary
                psth_struct.(bandname) = power_reformat_mnts(pc_log.(bandname), ...
                    component_results.(bandname), dir_config.bin_size, dir_config.window_start, dir_config.window_end);
            end

            matfile = fullfile(save_path, [filename_substring_one, ...
                '_format_' filename_meta.filename, '.mat']);
            save(matfile, 'psth_struct',  'filename_meta', 'config_log', ...
                'label_log', 'pc_log');
            clear('psth_struct', 'filename_meta', 'label_log', 'pc_log');
        catch ME
            handle_ME(ME, failed_path, filename_meta.filename);
        end
    end
end