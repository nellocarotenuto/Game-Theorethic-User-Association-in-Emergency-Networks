function [base_stations_info_table, user_association_table, changes_history] = game_theoretic_association(users_table, towers_table, uavs_table, limit_utilization, learning_rate)
%GAME_THEORETIC_ASSOCIATION  Performs User Association based on a non-cooperative game.
%   This function associates each user to the base station, among the
%   closest tower and the three closest UAVs, on the basis of perceived
%   throughput in a game-theoretic fashion.
% Inputs:
%   users_table         : a table containing info about the users in the
%                         area of interest
%   towers_table        : a table containing info about the towers in the
%                         area of interest
%   uavs_table          : a table cointaining info about UAVs in the area
%                         of interest
%   limit_utilization   : a boolean indicating whether to take into account
%                         any damage affecting tower cells
%   learning_rate       : a double indicating the rate at which users
%                         consolidate their choice with the mixed strategy
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
%   changes_history            : a vector reporting the number of changes
%                                at each iteration of the game

% Get the number of users
number_of_users = height(users_table);

% Store which is the closest base station of each type for every user
users_base_stations_table_fields = [["id", "uint16"];
                                    ["tower", "double"];
                                    ["tower_distance", "double"];
                                    ["tower_received_power", "double"];
                                    ["tower_channel_capacity", "double"];
                                    ["tower_total_received_power", "double"];
                                    ["uav_1", "double"];
                                    ["uav_1_distance", "double"];
                                    ["uav_1_received_power", "double"];
                                    ["uav_1_channel_capacity", "double"];
                                    ["uav_2", "double"];
                                    ["uav_2_distance", "double"];
                                    ["uav_2_received_power", "double"];
                                    ["uav_2_channel_capacity", "double"];
                                    ["uav_3", "double"];
                                    ["uav_3_distance", "double"];
                                    ["uav_3_received_power", "double"];
                                    ["uav_3_channel_capacity", "double"];
                                    ["uav_total_received_power", "double"]];

users_base_stations_table = table('Size', [number_of_users, length(users_base_stations_table_fields)], ...
                                  'VariableNames', users_base_stations_table_fields(:, 1), ...
                                  'VariableTypes', users_base_stations_table_fields(:, 2));

users_base_stations_table.id = users_table.id;


% Compute communications parameters for each of the considered base
% stations for every user
for i = 1 : number_of_users
    % Get current user info
    user = users_table(i, :);

    % Compute distance from towers excluding offline ones and find the
    % closest
    distance_from_towers = sqrt((user.x - towers_table.x) .^ 2 + (user.y - towers_table.y) .^ 2);
    distance_from_towers(towers_table.health == 0) = Inf;
    [closest_tower_distance, closest_tower_id] = min(distance_from_towers);
    
    users_base_stations_table.tower(i) = closest_tower_id;
    users_base_stations_table.tower_distance(i) = closest_tower_distance;
    users_base_stations_table.tower_received_power(i) = received_power(TOWER_MAX_TRANSMIT_POWER, closest_tower_distance);

    % Compute distance from UAVs and find the closest
    distance_from_uavs = sqrt((user.x - uavs_table.x) .^ 2 + (user.y - uavs_table.y) .^ 2);
    [sorted_uavs_distances, sorted_uavs_indexes] = sort(distance_from_uavs);
    
    users_base_stations_table.uav_1(i) = sorted_uavs_indexes(1);
    users_base_stations_table.uav_1_distance(i) = sorted_uavs_distances(1);
    users_base_stations_table.uav_1_received_power(i) = received_power(UAV_MAX_TRANSMIT_POWER, sorted_uavs_distances(1));
    
    users_base_stations_table.uav_2(i) = sorted_uavs_indexes(2);
    users_base_stations_table.uav_2_distance(i) = sorted_uavs_distances(2);
    users_base_stations_table.uav_2_received_power(i) = received_power(UAV_MAX_TRANSMIT_POWER, sorted_uavs_distances(2));
    
    users_base_stations_table.uav_3(i) = sorted_uavs_indexes(3);
    users_base_stations_table.uav_3_distance(i) = sorted_uavs_distances(3);
    users_base_stations_table.uav_3_received_power(i) = received_power(UAV_MAX_TRANSMIT_POWER, sorted_uavs_distances(3));
end


% Compute the total power received by each user from the base stations to
% be used for interference
for i = 1 : height(towers_table)    
    if towers_table.health(i) > 0
        tower = towers_table(i, :);
        user_distances_from_tower = sqrt((tower.x - users_table.x) .^ 2 + (tower.y - users_table.y) .^ 2);

        users_base_stations_table.tower_total_received_power = users_base_stations_table.tower_total_received_power + received_power(TOWER_MAX_TRANSMIT_POWER, user_distances_from_tower);
    end
end

for i = 1 : height(uavs_table)
    uav = uavs_table(i, :);
    user_distances_from_uav = sqrt((uav.x - users_table.x) .^ 2 + (uav.y - users_table.y) .^ 2);

    users_base_stations_table.uav_total_received_power = users_base_stations_table.uav_total_received_power + received_power(UAV_MAX_TRANSMIT_POWER, user_distances_from_uav);
end


% Compute user channel capacities
users_base_stations_table.tower_channel_capacity = channel_capacity(users_base_stations_table.tower_received_power, users_base_stations_table.tower_total_received_power); 

users_base_stations_table.uav_1_channel_capacity = channel_capacity(users_base_stations_table.uav_1_received_power, users_base_stations_table.uav_total_received_power); 
users_base_stations_table.uav_2_channel_capacity = channel_capacity(users_base_stations_table.uav_2_received_power, users_base_stations_table.uav_total_received_power); 
users_base_stations_table.uav_3_channel_capacity = channel_capacity(users_base_stations_table.uav_3_received_power, users_base_stations_table.uav_total_received_power); 


% Define a table to keep track of every parameter of the game for each user
game_table_fields = [["id", "uint16"];
                     ["strategy_type", "string"];
                     ["strategy_id", "uint8"];
                     ["tower_probability", "double"];
                     ["tower_score", "double"];
                     ["uav_1_probability", "double"];
                     ["uav_1_score", "double"];
                     ["uav_2_probability", "double"];
                     ["uav_2_score", "double"];
                     ["uav_3_probability", "double"];
                     ["uav_3_score", "double"];
                     ["peer_probability", "double"];
                     ["peer_score", "double"]];

game_table = table('Size', [number_of_users, length(game_table_fields)], ...
                   'VariableNames', game_table_fields(:, 1), ...
                   'VariableTypes', game_table_fields(:, 2));

game_table.id = users_table.id;


% Set up the initial association randomly
for i = 1 : number_of_users
    if rand < 0.5
        % Select the closest tower
        user_strategy_type = TOWER_LABEL;
        user_strategy_id = users_base_stations_table.tower(i);
    else
        % Select one of the three closest UAVs
        user_strategy_type = UAV_LABEL;
        
        uav_rand = rand;
        
        if uav_rand < (1/3)
            user_strategy_id = users_base_stations_table.uav_1(i);
        elseif uav_rand < (2/3)
            user_strategy_id = users_base_stations_table.uav_2(i);
        else
            user_strategy_id = users_base_stations_table.uav_3(i);
        end
    end
    
    game_table.strategy_type(i) = user_strategy_type;
    game_table.strategy_id(i) = user_strategy_id; 
end


% Set utilization limits for each base station
base_stations_utilization = vertcat(towers_table.health, ones(height(uavs_table), 1));


% Track the number of strategy changes
k = 1;
changes_history = 0;
changes = Inf;

while changes > 0
    current_strategy_type = game_table.strategy_type;
    current_strategy_id = game_table.strategy_id;
    changes = 0;
    
    for i = 1 : number_of_users
        % Get the current strategy for the user
        user_current_strategy_type = current_strategy_type(i);
        user_current_strategy_id = current_strategy_id(i);
        
        % Compute throughput for each strategy
        tower_users = current_strategy_type == TOWER_LABEL & current_strategy_id == users_base_stations_table.tower(i);
        tower_throughput = users_base_stations_table.tower_channel_capacity(i) / sum(tower_users) * base_stations_utilization(users_base_stations_table.tower(i));
        
        uav_1_users = current_strategy_type == UAV_LABEL & current_strategy_id == users_base_stations_table.uav_1(i);
        uav_1_throughput = users_base_stations_table.uav_1_channel_capacity(i) / sum(uav_1_users) * base_stations_utilization(height(towers_table) + users_base_stations_table.uav_1(i)); 
        
        uav_2_users = current_strategy_type == UAV_LABEL & current_strategy_id == users_base_stations_table.uav_2(i);
        uav_2_throughput = users_base_stations_table.uav_2_channel_capacity(i) / sum(uav_2_users) * base_stations_utilization(height(towers_table) + users_base_stations_table.uav_2(i)); 
        
        uav_3_users = current_strategy_type == UAV_LABEL & current_strategy_id == users_base_stations_table.uav_3(i);
        uav_3_throughput = users_base_stations_table.uav_3_channel_capacity(i) / sum(uav_3_users) * base_stations_utilization(height(towers_table) + users_base_stations_table.uav_3(i)); 
        
        % Compute utility of each strategy and update their recursive scores
        utilities = [tower_throughput, uav_1_throughput, uav_2_throughput, uav_3_throughput];
        
        game_table.tower_score(i) = game_table.tower_score(i) + utilities(1);
        game_table.uav_1_score(i) = game_table.uav_1_score(i) + utilities(2);
        game_table.uav_2_score(i) = game_table.uav_2_score(i) + utilities(3);
        game_table.uav_3_score(i) = game_table.uav_3_score(i) + utilities(4);
        
        % Compute the probability for each strategy       
        scores = [game_table.tower_score(i), game_table.uav_1_score(i), game_table.uav_2_score(i), game_table.uav_3_score(i)];
        
        % Compute utility deltas for each strategy
        tower_delta = -(game_table.tower_score(i) - max(scores));
        uav_1_delta = -(game_table.uav_1_score(i) - max(scores));
        uav_2_delta = -(game_table.uav_2_score(i) - max(scores));
        uav_3_delta = -(game_table.uav_3_score(i) - max(scores));
        
        % Update strategy probabilities
        tower_probability = 1 / (1 + exp(learning_rate * tower_delta));
        uav_1_probability = 1 / (1 + exp(learning_rate * uav_1_delta));
        uav_2_probability = 1 / (1 + exp(learning_rate * uav_2_delta));
        uav_3_probability = 1 / (1 + exp(learning_rate * uav_3_delta));
        
        % Normalize strategy probabilities
        p_unit = 1 / (tower_probability + uav_1_probability + uav_2_probability + uav_3_probability);
        
        p_tower = p_unit * tower_probability;
        p_uav_1 = p_unit * uav_1_probability;
        p_uav_2 = p_unit * uav_2_probability;
        p_uav_3 = p_unit * uav_3_probability;
        
        % Store each probability in the table
        game_table.tower_probability(i) = p_tower;
        game_table.uav_1_probability(i) = p_uav_1;
        game_table.uav_2_probability(i) = p_uav_2;
        game_table.uav_3_probability(i) = p_uav_3;
        
        % Choose the strategy to adopt
        n_r = rand;
        
        if n_r <= p_tower
            game_table.strategy_type(i) = TOWER_LABEL;
            game_table.strategy_id(i) = users_base_stations_table.tower(i);
        elseif n_r <= p_tower + p_uav_1
            game_table.strategy_type(i) = UAV_LABEL;
            game_table.strategy_id(i) = users_base_stations_table.uav_1(i);
        elseif n_r <= p_tower + p_uav_1 + p_uav_2
            game_table.strategy_type(i) = UAV_LABEL;
            game_table.strategy_id(i) = users_base_stations_table.uav_2(i);
        else
            game_table.strategy_type(i) = UAV_LABEL;
            game_table.strategy_id(i) = users_base_stations_table.uav_3(i);
        end
        
        % Count the change for the round if the chosen strategy differs
        % from the previous one
        if game_table.strategy_type(i) ~= user_current_strategy_type || ...
           game_table.strategy_id(i) ~= user_current_strategy_id  
            changes = changes + 1;
        end
    end
    
    % Record the number of changes
    changes_history(k) = changes;
    
    % Go to the next round
    k = k + 1;
end


% Build the table with base stations utilization info
base_stations_info_table_fields = [["type", "string"];
                                   ["id", "uint16"];
                                   ["x", "double"];
                                   ["y", "double"];
                                   ["transmit_power", "double"];
                                   ["users", "double"];
                                   ["average_throughput", "double"];
                                   ["health", "double"];
                                   ["utilization", "double"]];

base_stations_count = height(towers_table) + height(uavs_table);

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

% Traspose base stations info for each user to the output table
for i = 1 : number_of_users
    if game_table.strategy_type(i) == TOWER_LABEL
        % Tower strategy
        user_association_table.base_station_id(i) = users_base_stations_table.tower(i);
        user_association_table.base_station_type(i) = TOWER_LABEL;
        user_association_table.distance(i) = users_base_stations_table.tower_distance(i);
        user_association_table.transmit_power(i) = TOWER_MAX_TRANSMIT_POWER;
        user_association_table.received_power(i) = users_base_stations_table.tower_received_power(i);
        user_association_table.total_received_power(i) = users_base_stations_table.tower_total_received_power(i);
        user_association_table.channel_capacity(i) = users_base_stations_table.tower_channel_capacity(i);
        
        % Update load info for the associated base station
        base_station_index = base_stations_info_table.type == TOWER_LABEL & base_stations_info_table.id == users_base_stations_table.tower(i);
        base_stations_info_table.users(base_station_index) = base_stations_info_table.users(base_station_index) + 1;
    elseif game_table.strategy_type(i) == UAV_LABEL
        % UAV strategy
        user_association_table.base_station_type(i) = UAV_LABEL;
        user_association_table.transmit_power(i) = UAV_MAX_TRANSMIT_POWER;
        
        uav_id = game_table.strategy_id(i);
        
        if uav_id == users_base_stations_table.uav_1(i)
            user_association_table.base_station_id(i) = users_base_stations_table.uav_1(i);
            user_association_table.distance(i) = users_base_stations_table.uav_1_distance(i);
            user_association_table.received_power(i) = users_base_stations_table.uav_1_received_power(i);
            user_association_table.channel_capacity(i) = users_base_stations_table.uav_1_channel_capacity(i);
        elseif uav_id == users_base_stations_table.uav_2(i)
            user_association_table.base_station_id(i) = users_base_stations_table.uav_2(i);
            user_association_table.distance(i) = users_base_stations_table.uav_2_distance(i);
            user_association_table.received_power(i) = users_base_stations_table.uav_2_received_power(i);
            user_association_table.channel_capacity(i) = users_base_stations_table.uav_2_channel_capacity(i);
        else
            user_association_table.base_station_id(i) = users_base_stations_table.uav_3(i);
            user_association_table.distance(i) = users_base_stations_table.uav_3_distance(i);
            user_association_table.received_power(i) = users_base_stations_table.uav_3_received_power(i);
            user_association_table.channel_capacity(i) = users_base_stations_table.uav_3_channel_capacity(i);
        end
        
        user_association_table.total_received_power(i) = users_base_stations_table.uav_total_received_power(i);
        
        % Update load info for the associated base station
        base_station_index = base_stations_info_table.type == UAV_LABEL & base_stations_info_table.id == user_association_table.base_station_id(i);
        base_stations_info_table.users(base_station_index) = base_stations_info_table.users(base_station_index) + 1;
    end
end


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
