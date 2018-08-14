function [neuron_labels] = create_labels(original_path)
    % Grabs all the csv files
    csv_mat_path = [original_path, '/*.csv'];
    csv_files = dir(csv_mat_path);
    for file = 1: length(csv_files)
        if contains(csv_files(file).name, 'unit')
            % Auto-generated by MATLAB on 2018/08/14 11:15:11

            %% Initialize variables.
            filename = fullfile(original_path, csv_files(file).name);
            delimiter = ',';

            %% Format for each line of text:
            %   column20: categorical (%C)
            % For more information, see the TEXTSCAN documentation.
            formatSpec = '%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%C%[^\n\r]';
            
            %% Open the text file.
            fileID = fopen(filename,'r');
            
            %% Read columns of data according to the format.
            % This call is based on the structure of the file used to generate this
            % code. If an error occurs for a different file, try regenerating the code
            % from the Import Tool.
            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
            
            %% Close the text file.
            fclose(fileID);
            
            %% Post processing for unimportable data.
            % No unimportable data rules were applied during the import, so no post
            % processing code is included. To generate code which works for
            % unimportable data, select unimportable cells in a file and regenerate the
            % script.
            
            %% Create output variable
            unit_spreadsheet = table(dataArray{1:end-1}, 'VariableNames', {'neuron_label'});
            
            %% Clear temporary variables
            clearvars filename delimiter formatSpec fileID dataArray ans;
            %% End of auto-generated code
            neuron_labels = unit_spreadsheet.neuron_label;
            neuron_labels(1, :) = [];
        end
    end
end