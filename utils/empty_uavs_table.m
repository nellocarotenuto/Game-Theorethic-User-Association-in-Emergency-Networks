function uavs_table = empty_uavs_table
%EMPTY_UAV_TABLE Returns an empty UAVs table.

table_fields = [["id", "uint16"];
                ["x", "double"];
                ["y", "double"]];

uavs_table = table('Size', [0, length(table_fields)], ...
                   'VariableNames', table_fields(:, 1), ...
                   'VariableTypes', table_fields(:, 2));

end
