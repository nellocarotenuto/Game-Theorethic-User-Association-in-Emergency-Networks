function csv_splitter(folder, file_name, rows_per_file)
    % CSV_SPLITTER  Splits a CSV file in pieces of the desired size.
    %   This is an utility function that helps with the management of big
    %   CSV files by allowing to split them in smaller files of the size
    %   passed as parameter.
    % Inputs:
    %   folder          : the name of the folder where the file to split is
    %                     located
    %   file_name       : the name of the file to split
    %   rows_per_file   : the number of rows each new file should contain

    full_file_name = sprintf("%s/%s.csv", folder, file_name);
    
    datatable = readtable(full_file_name, "ReadVariableNames", true);
    number_of_rows = height(datatable);
    number_of_parts = ceil(number_of_rows / rows_per_file);
    
    if number_of_parts <= 1
        error("The file specified is too small and doesn't need splitting.");
    end
    
    fprintf("Splitting the file in %d parts... ", number_of_parts);
    
    for i = 1 : number_of_parts
        part_file_name = sprintf("%s/%s-%d.csv", folder, file_name, i);
        
        start_index = (i - 1) * rows_per_file + 1;
        end_index = min(i * rows_per_file, number_of_rows);
        
        writetable(datatable(start_index : end_index, :), part_file_name);    
    end
    
    fprintf(" done!\n");
    
end
