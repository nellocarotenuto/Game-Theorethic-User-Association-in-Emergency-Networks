function user_association_plot(users_table, towers_table, uavs_table, user_association_table, setting)
%USER_ASSOCIATION_PLOT  Allows to see how users are geographically split among the base stations.
% Inputs:
%   users_table              : a table containing info about the users in
%                              the area of interest
%   towers_table             : a table containing info about the towers in
%                              the area of interest
%   uavs_table               : a table cointaining info about UAVs in the
%                              area of interest
%   user_association_table   : a table reporting info about each user in
%                              terms of type and id of the associated base
%                              station
%   setting                  : a string describing the scenario to be
%                              plotted

% Set figure name and plot title
figure('Name', 'User Association');
title('User Association', setting);

% Set equal axis and plot limits
axis equal;

xlim([min(users_table.x) - 20, max(users_table.x) + 25]);
ylim([min(users_table.y) - 20, max(users_table.y) + 25]);

% Define colors to be used for each group of base stations users cyclically
tower_colors = [['#e5592e'];
                ['#ffba33'];
                ['#dbd945'];
                ['#33a39c'];
                ['#594fc7'];
                ['#82385c']];

uav_colors = [['#e53626'];
              ['#eb7500'];
              ['#ffd945'];
              ['#85bd00'];
              ['#0061ed'];
              ['#8259c2']];
          
tower_color = 0;
uav_color = 3;

% Merge towers and UAVs tables
towers_table = sortrows(towers_table, {'y', 'x'});
uavs_table = sortrows(uavs_table, {'y', 'x'});

table_fields = [["type", "string"];
                ["id", "uint16"];
                ["x", "double"];
                ["y", "double"]
                ["health", "double"]];

base_stations_number = height(towers_table) + height(uavs_table);

base_stations_table = table('Size', [base_stations_number, length(table_fields)], ...
                            'VariableNames', table_fields(:, 1), ...
                            'VariableTypes', table_fields(:, 2));

base_stations_table.type = vertcat(repmat(TOWER_LABEL, height(towers_table), 1), ...
                                   repmat(UAV_LABEL, height(uavs_table), 1));

base_stations_table.id = vertcat(towers_table.id, uavs_table.id);
base_stations_table.x = vertcat(towers_table.x, uavs_table.x);
base_stations_table.y = vertcat(towers_table.y, uavs_table.y);

base_stations_table.health = vertcat(towers_table.health, ...
                                     ones(height(uavs_table), 1));

% Retain plots
hold on;

for i = 1 : height(base_stations_table)
    % Get the current base station
    base_station = base_stations_table(i, :);
    
    % Set towers marker to triangle and UAVs to circle
    if base_station.type == TOWER_LABEL
        marker = '^';
        marker_size = 3;
        
        tower_color = 1 + mod(tower_color, height(tower_colors));
        plot_color = tower_colors(tower_color, :);
    elseif base_station.type == UAV_LABEL
        marker = 'o';
        marker_size = 4;
        
        uav_color = 1 + mod(uav_color, height(uav_colors));
        plot_color = uav_colors(uav_color, :);
    end
    
    % Set plot color to grey for offline base stations
    if base_station.health == 0
        plot_color = '#e5e5e5';
    end
    
    % Select all users of the current base station and plot them as dots
    base_station_users = user_association_table.id(user_association_table.base_station_type == base_station.type & user_association_table.base_station_id == base_station.id);
    plot(users_table.x(base_station_users), users_table.y(base_station_users), 'Color', plot_color, 'Marker', '.', 'LineStyle', 'none', 'MarkerSize', 8);
    
    % Plot the current base station with a black border and add its id
    plot(base_station.x, base_station.y, 'Color', '#000000', 'Marker', marker, 'LineWidth', 3, 'MarkerSize', marker_size);
    plot(base_station.x, base_station.y, 'Color', plot_color, 'MarkerFaceColor', plot_color, 'Marker', marker, 'LineWidth', 2, 'MarkerSize', marker_size);
    text(base_station.x, base_station.y, pad(num2str(base_station.id), 4, 'left'), 'FontSize', 6, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    
    % Add an exclamation mark to damaged base stations
    if base_station.health > 0 && base_station.health < 1
        text(base_station.x, base_station.y, pad('!', 2, 'left'), 'FontSize', 8, 'FontWeight', 'bold', 'VerticalAlignment', 'bottom');
    end
end

% Add the generic legend
h = zeros(3, 1);
h(1) = plot(NaN,NaN,'.k');
h(2) = plot(NaN,NaN,'^k');
h(3) = plot(NaN,NaN,'ok');
legend(h, 'Users', 'Towers', 'UAVs', 'location', 'northeastoutside');

hold off;

end
