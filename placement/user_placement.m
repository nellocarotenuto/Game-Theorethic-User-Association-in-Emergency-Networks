function users_table = user_placement(vertex_1, vertex_2, altitude, number_of_users)
%USER_PLACEMENT  Randomly places users on the plane.
%   This function allows to place a desired number of users in the
%   rectangular area delimited by the two diagonally opposed vertices
%   parameters.
% Inputs:
%   vertex_1   : a 1-by-2 vector with latitude and longitude components of
%                the first point that will be used to select the area of
%                operation
%   vertex_2   : a 1-by-2 vector with latitude and longitude components of
%                the second point that will be used to select the area of
%                operation (diagonally opposed to the first)
%   altitude   : the average altitude of the area of interest, expressed in
%                meters
% Outputs:
%   users_table   : a table with id, x, y and battery properties of the
%                   users placed on the plane

origin = [min(vertex_1(1), vertex_2(1)) + (max(vertex_1(1), vertex_2(1)) - min(vertex_1(1), vertex_2(1))) / 2, ...
          min(vertex_1(2), vertex_2(2)) + (max(vertex_1(2), vertex_2(2)) - min(vertex_1(2), vertex_2(2))) / 2, altitude];

[x_range, y_range] = latlon2local([vertex_1(1), vertex_2(1)], [vertex_1(2), vertex_2(2)], altitude, origin);

ids = uint16([1 : number_of_users]');

x = min(x_range) + (max(x_range) - min(x_range)) .* rand(number_of_users, 1);
y = min(y_range) + (max(y_range) - min(y_range)) .* rand(number_of_users, 1);

battery = rand(number_of_users, 1);

users_table = table(ids, x, y, battery, ...
                    'VariableNames', ["id", "x", "y", "battery"]);

end
