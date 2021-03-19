% Add functions to path
addpath('association', 'constants', 'data', 'evaluation', 'disruption', 'performance', 'placement', 'utils');

% Set random number generator seed for reproducibility
rng(6);

% Definition of the area of interest
vertex_1 = [40.77405, 14.79425];
vertex_2 = [40.76728, 14.80319];

altitude = 280;

origin = [min(vertex_1(1), vertex_2(1)) + (max(vertex_1(1), vertex_2(1)) - min(vertex_1(1), vertex_2(1))) / 2, ...
          min(vertex_1(2), vertex_2(2)) + (max(vertex_1(2), vertex_2(2)) - min(vertex_1(2), vertex_2(2))) / 2, altitude];

% Selection of network operator and technology
radio = ["LTE", "UMTS"];
mcc = 222;
mnc = [10, 6];

fprintf('Getting towers in the area ...');
towers_table = tower_placement(vertex_1, vertex_2, origin, altitude, radio, mcc, mnc);
fprintf('done!\n');

% User placement
number_of_users = 500;

fprintf('Placing users in the area ...');
users_table = user_placement(vertex_1, vertex_2, altitude, number_of_users);
fprintf('done!\n');

% Signal-based user association before disaster
fprintf('Performing signal-based user association before disaster ...');
[base_stations_info_table_sbbd, user_association_table_sbbd] = signal_based_association(users_table, towers_table, empty_uavs_table, true);
user_association_plot(users_table, towers_table, empty_uavs_table, user_association_table_sbbd, 'Signal-based pre-disaster');
fprintf('done!\n');

% Natural disaster simulation
center = [0, 0];
radius = 250;
destruction_probability = 0.4;
damage_probability = 0.8;

fprintf('Simulating disaster ...');
towers_table_ad = natural_disaster(center, radius, destruction_probability, damage_probability, towers_table);
fprintf('done!\n');

% Signal-based user association after disaster without UAVs
fprintf('Performing signal-based user association before disaster ...');
[base_stations_info_table_sbad, user_association_table_sbad] = signal_based_association(users_table, towers_table_ad, empty_uavs_table, true);
user_association_plot(users_table, towers_table_ad, empty_uavs_table, user_association_table_sbad, 'Signal-based post-disaster');
fprintf('done!\n');

% UAV placement
cell_size = 20;
max_uavs = 48;

fprintf('Placing UAVs in the area (this may take a while) ...\n');
uavs_table = uav_placement(vertex_1, vertex_2, origin, altitude, cell_size, max_uavs, users_table, towers_table_ad);

% Signal-based user association after disaster with UAVs deployed
fprintf('Performing signal-based user association after UAV deployment ...');
[base_stations_info_table_sbadwu, user_association_table_sbadwu] = signal_based_association(users_table, towers_table_ad, uavs_table, true);
user_association_plot(users_table, towers_table_ad, uavs_table, user_association_table_sbadwu, 'Signal-based post-disaster with UAVs deployed');
fprintf('done!\n');

% Game-theoretic user association after disaster with UAVs deployed
game_learning_rate = 0.05;

fprintf('Performing game-theoretic user association after UAV deployment ...');
[base_stations_info_table_gtadwu, user_association_table_gtadwu, changes_history] = game_theoretic_association(users_table, towers_table_ad, uavs_table, true, game_learning_rate);
user_association_plot(users_table, towers_table_ad, uavs_table, user_association_table_gtadwu, 'Game-theoretic post-disaster with UAVs deployed');
fprintf('done!\n');

% Plot user throughput distributions
throughput_distributions = [user_association_table_gtadwu.throughput user_association_table_sbadwu.throughput user_association_table_sbad.throughput user_association_table_sbbd.throughput];
labels = {'Ottimizzato', 'Post-disastro con UAV', 'Post-disastro', 'Pre-disastro'};
throughput_distribution_plot(throughput_distributions, labels);

% Plot the number of strategy changes for each round of the game
game_changes_history_plot(changes_history);