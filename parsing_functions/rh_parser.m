function [] = rh_parser(parsed_path, failed_path, raw_file, config, label_table)
    try
        %% reads and maps data
        if strcmpi(config.rh, 'rhs')
            [amplifier_channels, amplifier_data, board_adda_channels, board_adda_data, ...
                board_dig_in_data, t_amplifier, sample_rate] = read_Intan_RHS2000_file(raw_file);
        elseif strcmpi(config.rh, 'rhd')
            [amplifier_channels, amplifier_data, board_adda_channels, board_adda_data, ...
                board_dig_in_data, t_amplifier, sample_rate] = read_Intan_RHD2000_file(raw_file);
        else
            error('Expected rhs or rhd files, but given %s', config.rh);
        end
        [~, tot_amp_channels] = size(amplifier_channels);
        wideband_map = cell(tot_amp_channels, 2);
        [~, tot_adda_channels] = size(board_adda_channels);
        analog_input_map = cell(tot_adda_channels, 2);
        % amplifier data mapping
        for channel = 1:tot_amp_channels
            wideband_map(channel, :) = [ ...
                {amplifier_channels(channel).native_channel_name}, ...
                {amplifier_data(channel, :)} ...
            ];
        end
        wideband_map(:, 1) = cellfun(@(x) strrep(x, '-', '_'), wideband_map(:, 1), 'UniformOutput',false);
        % ad/da data mapping
        for channel = 1:tot_adda_channels
            analog_input_map = [ ...
                {board_adda_channels(channel).native_channel_name}, ...
                {board_adda_data(channel, :)} ...
            ];
        end

        %% label channel map
        [~, filename, ~] = fileparts(raw_file);
        filename_meta = get_filename_info(filename);

        event_samples = find_event_samples(board_dig_in_data);

        labeled_data = label_data(wideband_map, label_table, ...
            filename_meta.session_num);

        channel_list = wideband_map(:, 1);
        label_list = label_table.sig_channels(filename_meta.session_num == label_table.recording_session);
        enforce_labels(channel_list, label_list, filename_meta.session_num);

        %% Saves parsed files
        matfile = fullfile(parsed_path, [filename, '.mat']);
        save(matfile, '-v7.3', 'analog_input_map', ...
            'board_dig_in_data', 't_amplifier', 'sample_rate', ...
            'filename_meta', 'labeled_data', 'event_samples');
        clear('analog_input_map', 'board_dig_in_data', 't_amplifier', ...
            'sample_rate', 'filename_meta', 'labeled_data', 'event_samples');
    catch ME
        handle_ME(ME, failed_path, filename);
    end
end