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
%   users_table   : a table with id, x, y, tower, tower_mean_loss, 
%                   tower_ratio, tower_mean_energy, uav, uav_mean_loss,
%                   uav_ratio, peer, peer_mean_loss, peer_ratio and
%                   peer_mean_energy properties of the users placed on the
%                   plane

origin = [min(vertex_1(1), vertex_2(1)) + (max(vertex_1(1), vertex_2(1)) - min(vertex_1(1), vertex_2(1))) / 2, ...
          min(vertex_1(2), vertex_2(2)) + (max(vertex_1(2), vertex_2(2)) - min(vertex_1(2), vertex_2(2))) / 2, altitude];

[x_range, y_range] = latlon2local([vertex_1(1), vertex_2(1)], [vertex_1(2), vertex_2(2)], altitude, origin);

ids = uint16([1 : number_of_users]');

x = min(x_range) + (max(x_range) - min(x_range)) .* rand(number_of_users, 1);
y = min(y_range) + (max(y_range) - min(y_range)) .* rand(number_of_users, 1);

towers = zeros(number_of_users, 1, 'uint16');
towers_mean_loss = zeros(number_of_users, 1);
towers_traffic_ratio = zeros(number_of_users, 1);
towers_mean_energy = zeros(number_of_users, 1);

uavs = zeros(number_of_users, 1, 'uint16');
uavs_mean_loss = zeros(number_of_users, 1);
uavs_traffic_ratio = zeros(number_of_users, 1);
uavs_mean_energy = zeros(number_of_users, 1);

peers = zeros(number_of_users, 1, 'uint16');
peers_mean_loss = zeros(number_of_users, 1);
peers_traffic_ratio = zeros(number_of_users, 1);
peers_mean_energy = zeros(number_of_users, 1);

users_table = table(ids, x, y, towers, towers_mean_loss, towers_traffic_ratio, towers_mean_energy, uavs, uavs_mean_loss, uavs_traffic_ratio, uavs_mean_energy, peers, peers_mean_loss, peers_traffic_ratio, peers_mean_energy, ...
                    'VariableNames', ["id", "x", "y", "tower", "tower_mean_loss", "tower_ratio", "tower_mean_energy", "uav", "uav_mean_loss", "uav_ratio", "uav_mean_energy", "peer", "peer_mean_loss", "peer_ratio", "peer_mean_energy"]);

end
