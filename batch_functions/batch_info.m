%varargin is for variable ignore_sessions
function [] = batch_info(animal_name, data_path, dir_name, ...
    search_ext, filename_substring_one, filename_substring_two, varargin)
    info_start = tic;
    
    ignore_sessions = [];
    if length(varargin) > 1
        msg = 'Too many arguments';
        error(msg)
    elseif length(varargin) == 1
        ignore_sessions = varargin{1};
        if ~ismatrix(ignore_sessions)
            msg = 'Input ignore_sessions is not a matrix';
            error(msg)
        end
    end
    
    if isempty(ignore_sessions)
        [files, info_path, failed_path] = create_dir(data_path, dir_name, search_ext);
    else
        [files, info_path, failed_path] = create_dir(data_path, dir_name, search_ext, ignore_sessions);
    end

    fprintf('Mutual Info for %s \n', animal_name);
    %% Goes through all the files and calculates mutual info according to the parameters set in config
    for file_index = 1:length(files)
        try
            %% pull info from filename and set up file path for analysis
            file = fullfile(data_path, files(file_index).name);
            [~, filename, ~] = fileparts(file);
            filename = erase(filename, [filename_substring_one, '.', filename_substring_two, '.']);
            filename = erase(filename, [filename_substring_one, '_', filename_substring_two, '_']);
            load(file, 'response_window', 'labeled_data');
            %% Check psth variables to make sure they are not empty
            empty_vars = check_variables(file, response_window, labeled_data);
            if empty_vars
                warning('Animal: %s Does not have all the variables required for this analysis. Skipping...', animal_name);
                continue
            end

            %% Mutual information
            [prob_struct, mi_results] = mutual_info(response_window, labeled_data);

            %% Saving the file
            matfile = fullfile(info_path, ['mutual_info_', filename, '.mat']);
            check_variables(matfile, prob_struct, mi_results);
            save(matfile, 'labeled_data', 'prob_struct', 'mi_results');
        catch ME
            handle_ME(ME, failed_path, filename);
        end
    end
    fprintf('Finished information analysis for %s. It took %s \n', ...
        animal_name, num2str(toc(info_start)));
end