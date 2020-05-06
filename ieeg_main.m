function [] = ieeg_main()
    %% Get data directory
    project_path = uigetdir(pwd);
    start_time = tic;

    %% Import psth config and removes ignored animals
    config = import_config(project_path, 'ieeg');
    config(config.include_dir == 0, :) = [];

    [raw_path, raw_failed_path] = create_dir(project_path, 'raw');
    dir_list = config.dir_name;
    for dir_i = 1:length(dir_list)
        curr_dir = dir_list{dir_i};
        dir_config = config(dir_i, :);
        dir_config = convert_table_cells(dir_config);

        if dir_config.make_labels
            %% Set up labels
            labels_path = [project_path, '/', curr_dir, '_labels.csv'];
            if exist(labels_path)
                label_table = load_labels(project_path, [curr_dir, '_labels.csv']);
            else
                headers = {'sig_channels', 'selected_channels', ...
                    'user_channels', 'label', 'label_id', ...
                    'recording_session', 'recording_notes'};
                var_types = {'cell', 'double', 'cell', 'cell', 'double', ...
                    'double', 'cell'};
                label_table = table('Size', [0, length(headers)], 'VariableTypes', ...
                    var_types, 'VariableNames', headers);
            end

            %% Check for raw path for current directory
            e_msg_1 = 'No raw directory to make labels';
            e_msg_2 = ['No ', curr_dir, ' directory to create labels'];
            raw_dir_path = enforce_dir_layout(raw_path, curr_dir, ...
                raw_failed_path, e_msg_1, e_msg_2);
            %% Call batch labeller to make labels
            batch_create_labels(raw_dir_path, raw_failed_path, labels_path, ...
                label_table, dir_config);
        end

        %% Load labels file to start analysis
        label_table = load_labels(project_path, [curr_dir, '_labels.csv']);

        if dir_config.create_mnts
            try
                [mnts_path, mnts_failed_path] = create_dir(project_path, 'mnts');
                [data_path, ~] = create_dir(mnts_path, 'mnts_data');
                %% Check to make sure paths exist for analysis and create save path
                e_msg_1 = 'No raw directory to make mnts';
                e_msg_2 = ['No ', curr_dir, ' directory to create mnts'];
                raw_dir_path = enforce_dir_layout(raw_path, curr_dir, ...
                    raw_failed_path, e_msg_1, e_msg_2);
                [dir_save_path, dir_failed_path] = create_dir(data_path, curr_dir);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%        Format MNTS         %%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                batch_reshape_to_mnts(dir_save_path, dir_failed_path, ...
                    raw_dir_path, curr_dir, dir_config, label_table);
            catch ME
                handle_ME(ME, mnts_failed_path, [curr_dir, '_missing_dir.mat']);
            end
        end

        if dir_config.do_pca %TODO change to pc_analysis
            try
                [pca_path, pca_failed_path] = create_dir(mnts_path, 'pca');
                %% Check to make sure paths exist for analysis and create save path
                e_msg_1 = 'No data directory to find MNTSs';
                e_msg_2 = ['No ', curr_dir, ' mnts data for pca'];
                dir_mnts_path = enforce_dir_layout(data_path, curr_dir, mnts_failed_path, e_msg_1, e_msg_2);
                [dir_save_path, dir_failed_path] = create_dir(pca_path, curr_dir);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %             PCA            %%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                batch_power_pca(dir_save_path, dir_failed_path, dir_mnts_path, ...
                    curr_dir, dir_config)
            catch ME
                handle_ME(ME, mnts_failed_path, [curr_dir, '_missing_dir.mat']);
            end
        end

        if config.make_pca_plots
            [graph_path, graph_failed_path] = create_dir(mnts_path, 'pca_graphs');
            export_params(graph_path, 'pca_graph', config);
            try
                %% Check to make sure paths exist for analysis and create save path
                e_msg_1 = 'No data directory to find PCAs';
                e_msg_2 = ['No ', curr_dir, ' pca data for graphing'];
                pca_path = [mnts_path, '/pca'];
                dir_pca_path = enforce_dir_layout(pca_path, curr_dir, graph_failed_path, e_msg_1, e_msg_2);
                [dir_save_path, dir_failed_path] = create_dir(graph_path, curr_dir);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%         Graph PSTH         %%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                batch_plot_pca_weights(dir_save_path, dir_failed_path, dir_pca_path, curr_dir, dir_config)
            catch ME
                handle_ME(ME, graph_failed_path, [curr_dir, '_missing_dir.mat']);
            end
        end
    end
end