function [base_stations_info_table, user_association_table] = signal_based_association(users_table, towers_table, uavs_table, limit_utilization)
%SIGNAL_BASED_ASSOCIATION  Implememts User Association on received signal strength basis.
%   This function associates each user to base station transmitting the
%   strongest signal, returning info about the stations load as well as
%   users throughput.
%   Base stations utilization is kept at the minimum necessary to guarantee
%   that the average throughput for their users matches TARGET_THROUGHPUT.
% Inputs:
%   users_table         : a table containing info about the users in the
%                         area of interest
%   towers_table        : a table containing info about the towers in the
%                         area of interest
%   uavs_table          : a table cointaining info about UAVs in the area
%                         of interest
%   limit_utilization   : a boolean indicating whether to take into account
%                         any damage affecting tower cells
% Outputs:
%   base_stations_info_table   : a table reporting load info about each
%                                base station in terms of number of
%                                associated users, utilization and average
%                                throughput perceived by their users
%   user_association_table     : a table reporting info about each user in
%                                terms of type and id of the associated
%                                base station, the distance from it as well
%                                as received power with and without
%                                interference, channel capacity and
%                                perceived throughput

% Build the unified base stations table with base stations load and quality
% of service info
base_stations_count = height(towers_table) + height(uavs_table);

base_stations_info_table_fields = [["type", "string"];
                                   ["id", "uint16"];
                                   ["x", "double"];
                                   ["y", "double"];
                                   ["transmit_power", "double"];
                                   ["users", "double"];
                                   ["average_throughput", "double"];
                                   ["health", "double"];
                                   ["utilization", "double"]];

base_stations_info_table = table('Size', [base_stations_count, length(base_stations_info_table_fields)], ...
                                 'VariableNames', base_stations_info_table_fields(:, 1), ...
                                 'VariableTypes', base_stations_info_table_fields(:, 2));

base_stations_info_table.type = vertcat(repmat(TOWER_LABEL, height(towers_table), 1), repmat(UAV_LABEL, height(uavs_table), 1));
base_stations_info_table.id = vertcat(towers_table.id, uavs_table.id);
base_stations_info_table.x = vertcat(towers_table.x, uavs_table.x);
base_stations_info_table.y = vertcat(towers_table.y, uavs_table.y);

base_stations_info_table.transmit_power(base_stations_info_table.type == TOWER_LABEL) = TOWER_MAX_TRANSMIT_POWER;
base_stations_info_table.transmit_power(base_stations_info_table.type == UAV_LABEL) = UAV_MAX_TRANSMIT_POWER;

base_stations_info_table.health = ones(height(base_stations_info_table), 1);

if limit_utilization
    base_stations_info_table.health(base_stations_info_table.type == TOWER_LABEL) = towers_table.health;
end

% Build the table with user association info
user_association_table_fields = [["id", "uint16"];
                                 ["base_station_type", "string"];
                                 ["base_station_id", "uint16"];
                                 ["distance", "double"];
                                 ["base_station_users", "double"];
                                 ["base_station_utilization", "double"];
                                 ["transmit_power", "double"];
                                 ["received_power", "double"];
                                 ["total_received_power", "double"];
                                 ["channel_capacity", "double"];
                                 ["throughput", "double"]];

user_association_table = table('Size', [height(users_table), length(user_association_table_fields)], ...
                               'VariableNames', user_association_table_fields(:, 1), ...
                               'VariableTypes', user_association_table_fields(:, 2));

user_association_table.id = users_table.id;

% Perform user association based on the power received from each base
% station
for i = 1 : height(users_table)
	% Get the current user
    user = users_table(i, :);
    
    % Compute user distance from each base station and the amount of power
    % received from each of them
    user_base_stations_distances = sqrt((user.x - base_stations_info_table.x) .^ 2 + (user.y - base_stations_info_table.y) .^ 2);
    user_base_stations_power = received_power(base_stations_info_table.transmit_power, user_base_stations_distances);

    % Exclude base stations that are completely offline
    user_base_stations_power(base_stations_info_table.health == 0) = -Inf;
   
    % Find the station with the biggest amount of power
    [user_power, base_station_index] = max(user_base_stations_power);
    
    % Get the associated base station
    base_station = base_stations_info_table(base_station_index, :);
    
    % Update user association info
    user_association_table.base_station_type(i) = base_station.type;
    user_association_table.base_station_id(i) = base_station.id;
    user_association_table.distance(i) = user_base_stations_distances(base_station_index);
    user_association_table.received_power(i) = user_power;
    user_association_table.transmit_power(i) = base_stations_info_table.transmit_power(base_station_index);
    
    % Update load info for the associated base station
    base_stations_info_table.users(base_station_index) = base_stations_info_table.users(base_station_index) + 1;
end

% Compute the total power received by each user from the base stations for
% to be used for interference
for i = 1 : height(base_stations_info_table)    
    if base_stations_info_table.health(i) > 0
        base_station = base_stations_info_table(i, :);
        user_distances_from_tower = sqrt((base_station.x - users_table.x) .^ 2 + (base_station.y - users_table.y) .^ 2);

        user_association_table.total_received_power = user_association_table.total_received_power + received_power(user_association_table.transmit_power, user_distances_from_tower);
    end
end

% Compute user channel capacities
user_association_table.channel_capacity = channel_capacity(user_association_table.received_power, user_association_table.total_received_power); 

% Compute base stations utilization
for i = 1 : height(base_stations_info_table)
    base_station = base_stations_info_table(i, :);
    
    base_station_users_indices = user_association_table.base_station_type == base_station.type & user_association_table.base_station_id == base_station.id;
    base_station_users_count = sum(base_station_users_indices);
    
    if base_station_users_count > 0
        
        if limit_utilization
            utilization = min(1, base_stations_info_table.health(i));
        else
            utilization = 1;
        end
        
        throughput = base_station_average_throughput(user_association_table.channel_capacity(base_station_users_indices), base_station_users_count, utilization);
        
        while 1
            test_utilization = utilization - 0.01;
            test_throughput = base_station_average_throughput(user_association_table.channel_capacity(base_station_users_indices), base_station_users_count, test_utilization);
            
            if test_throughput < TARGET_THROUGHPUT
                break
            end
            
            utilization = test_utilization;
            throughput = test_throughput;
        end

        base_stations_info_table.utilization(i) = utilization;
        base_stations_info_table.average_throughput(i) = throughput;
        
        user_association_table.base_station_utilization(base_station_users_indices) = utilization;
        user_association_table.base_station_users(base_station_users_indices) = base_station_users_count;
    end
end

% Compute user throughput
user_association_table.throughput = user_association_table.channel_capacity ./ user_association_table.base_station_users .* user_association_table.base_station_utilization;

end
