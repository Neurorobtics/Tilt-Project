function highpass_filtered_path = do_highpass_filter(animal_name, parsed_path, notch_filtered_path, ...
    is_notch_filter, is_lowpass_filter, highpass_filter_order, highpass_filter_fc)
    highpass_filter_start = tic;               
    fprintf('Applying highpass filter for %s \n', animal_name);
    if is_notch_filter
        file_type = [notch_filtered_path, '/*', '.mat'];
        selected_files = dir(file_type);
        failed_path = [parsed_path, '/failed_', 'filtered'];
        files_path = notch_filtered_path;
        highpass_filtered_path = notch_filtered_path;
    else
        [selected_files, highpass_filtered_path, failed_path] = create_dir...
            (parsed_path, 'filtered', '.mat');
        files_path = parsed_path;                    
    end
    for file_index = 1:length(selected_files)
        try
            %% Load file contents
            file = [files_path, '/', selected_files(file_index).name];
            [~, filename, ~] = fileparts(file);

            if is_notch_filter
                matfile = fullfile(highpass_filtered_path, [filename, '.mat']); 
                load(file, 'notch_filtered_map', 'sample_rate');
                empty_vars = check_variables(file, notch_filtered_map, sample_rate);
                if empty_vars
                    continue
                end
                board_band_map = notch_filtered_map;
            else
                matfile = fullfile(highpass_filtered_path, ['filtered_', filename, '.mat']);
                load(file, 'board_band_map', 'board_dig_in_data', 'sample_rate');
                empty_vars = check_variables(file, board_band_map, sample_rate);
                if empty_vars
                continue
                end
            end                         
            %% Apply highpass filter
            highpass_filtered_map = highpass_filter_for_boardband(board_band_map, ...
                highpass_filter_order, highpass_filter_fc, sample_rate);
            %% Check output to make sure there are no issues with the output
            empty_vars = check_variables(highpass_filtered_map);
            if empty_vars
                continue
            end

            %% Saving outputs
            if (is_notch_filter ||  is_lowpass_filter)
                save(matfile, 'highpass_filtered_map', '-append');                        
            else
                save(matfile, 'highpass_filtered_map', 'board_dig_in_data', 'sample_rate'); 
            end

        catch ME
            handle_ME(ME, failed_path, filename);
        end
    end  
    fprintf('Finished applying highpass filter for %s. It took %s s\n', ...
        animal_name, num2str(toc(highpass_filter_start)));

end