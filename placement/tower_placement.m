function towers_table = tower_placement(vertex_1, vertex_2, origin, altitude, radio, mcc, mnc)
%TOWER_PLACEMENT  Returns the tower cells a specific area.
%   This function returns placement and coverage info about tower cells in
%   the rectangular area delimited by the two diagonally opposed vertices
%   parameters.
% Inputs:
%   vertex_1   : a 1-by-2 vector with latitude and longitude components of
%                the first point that will be used to select the area of
%                operation
%   vertex_2   : a 1-by-2 vector with latitude and longitude components of
%                the second point that will be used to select the area of
%                operation (diagonally opposed to the first)
%   origin     : a 1-by-3 vector with latitude, longitude and altitude of
%                the point to use as the origin after the conversion to
%                cartesian coordinates
%   altitude   : the average altitude of the area of interest, expressed in
%                meters
%   radio      : an array of strings indicating the radio type of the
%                towers to select (LTE, UMTS, GSM, ...)
%   mcc        : the country identifier of the network operator whose
%                towers should be selected
%   mnc        : an array of identifiers of the network operator whose
%                towers should be selected
% Outputs:
%   towers_table   : a table with id, x, y and health properties of the
%                    towers in the area of interest

input_fields = [["radio", "string"];
                ["mcc", "double"];
                ["net", "double"];
                ["lat", "double"];
                ["lon", "double"]];

full_towers_table = table('Size', [0, length(input_fields)], ...
                          'VariableNames', input_fields(:, 1), ...
                          'VariableTypes', input_fields(:, 2));
                      
csv_files = dir('data/*.csv');
                      
for i = 1 : length(csv_files)
    file_towers_table = readtable(sprintf("data/%s", csv_files(i).name), ...
                                  'ReadVariableNames', true);
                        
    file_towers_table = file_towers_table(file_towers_table.lat >= min(vertex_1(1), vertex_2(1)) & ...
                                          file_towers_table.lat <= max(vertex_1(1), vertex_2(1)) & ...
                                          file_towers_table.lon >= min(vertex_1(2), vertex_2(2)) & ...
                                          file_towers_table.lon <= max(vertex_1(2), vertex_2(2)), ...
                                          ["radio", "mcc", "net", "lat", "lon"]);
    
    full_towers_table = vertcat(full_towers_table, file_towers_table);
end

towers_of_interest = ismember(full_towers_table.radio, radio) & ...
                              full_towers_table.mcc == mcc & ...
                              ismember(full_towers_table.net, mnc);
                    
full_towers_table = full_towers_table(towers_of_interest, :);

[x, y] = latlon2local(table2array(full_towers_table(: , "lat")), ...
                      table2array(full_towers_table(: , "lon")), ...
                      altitude, origin);

ids = uint16([1 : height(full_towers_table)]');
health = ones(height(full_towers_table), 1);

towers_table = table(ids, x, y, health, ...
                     'VariableNames', ["id", "x", "y", "health"]);

end
