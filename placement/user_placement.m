function users_table = user_placement(x_range, y_range, number_of_users)
%USER_PLACEMENT  Randomly places users on the plane.
%   This function allows to place a desired number of users in the area of
%   the plane specified by range intervals.
% Inputs:
%   x_range           : a 1x2 vector indicating the range of values for the
%                       x component (not necessarily ordered)
%   y_range           : a 1x2 vector indicating the range of values for the
%                       y component (not necessarily ordered)
%   number_of_users   : the desired number of users to place on the plane
% Outputs:
%   users_table   : a table with id, x, y, tower, tower_mean_loss, 
%                   tower_ratio, uav, uav_mean_loss, uav_ratio, peer,
%                   peer_mean_loss and peer_ratio properties of the users
%                   placed on the plane

if ~isequal(size(x_range), [1, 2]) || ~isequal(size(y_range), [1, 2])
    error("Input parameters should be 1x2 arrays for both x and y ranges.");
end

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
                    'VariableNames', ["id", "x", "y", "tower", "tower_mean_loss", "tower_ratio", "uav", "uav_mean_loss", "uav_ratio", "peer", "peer_mean_loss", "peer_ratio"]);

end
