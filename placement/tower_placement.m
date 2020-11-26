function towers_table = tower_placement(vertex_1, vertex_2)
%TOWER_PLACEMENT  Returns the tower cells a specific area.
%   This function returns placement and coverage info about tower cells in
%   the rectangular area delimited by the two diagonally opposed vertices
%   parameters.
% Inputs:
%   vertex_1   : a 1-by-2 vector with latitude and longitude components of
%                the point that will be used as origin
%   vertex_2   : a 1-by-2 vector with latitude and longitude components of
%                the point diagonally opposed to the origin
% Outputs:
%   towers_table   : a table with id, x, y, range, max_users and worsening
%                    properties of the towers in the area of interest,
%                    where coordinates and range are expressed in meters


if ~isequal(size(vertex_1), [1, 2]) || ~isequal(size(vertex_2), [1, 2])
    error("Input parameters should be [latitude longitude] arrays.");
end

input_fields = [["radio", "string"];
                ["lat", "double"];
                ["lon", "double"];
                ["range", "double"]];

full_towers_table = table('Size', [0, length(input_fields)], ...
                          'VariableNames', input_fields(:, 1), ...
                          'VariableTypes', input_fields(:, 2));
                      
csv_files = dir('data/*.csv');
                      
for i = 1 : length(csv_files)
    file_towers_table = readtable(sprintf("data/%s", csv_files(i).name), ...
                            'ReadVariableNames', true);
                        
    file_towers_table = file_towers_table( ...
                            file_towers_table.lat >= min(vertex_1(1), vertex_2(1)) & ...
                            file_towers_table.lat <= max(vertex_1(1), vertex_2(1)) & ...
                            file_towers_table.lon >= min(vertex_1(2), vertex_2(2)) & ...
                            file_towers_table.lon <= max(vertex_1(2), vertex_2(2)), ["radio", "lat", "lon", "range"]);
    
    full_towers_table = vertcat(full_towers_table, file_towers_table);
end

full_towers_table = unique(full_towers_table, 'rows');

origin = [min(vertex_1(1), vertex_2(1)) + (max(vertex_1(1), vertex_2(1)) - min(vertex_1(1), vertex_2(1))) / 2, ...
          min(vertex_1(2), vertex_2(2)) + (max(vertex_1(2), vertex_2(2)) - min(vertex_1(2), vertex_2(2))) / 2, 300];

[x, y] = latlon2local(table2array(full_towers_table(: , "lat")), ...
                      table2array(full_towers_table(: , "lon")), 10, origin);

ids = zeros(height(full_towers_table), 1, 'uint16');
range = table2array(full_towers_table(: , "range"));
worsening = zeros(height(full_towers_table), 1);
max_users = randi([750 1250], height(full_towers_table), 1);

towers_table = table(ids, x, y, range, max_users, worsening, ...
                     'VariableNames', ["id", "x", "y", "range", "max_users", "worsening"]);

end
