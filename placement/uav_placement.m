function uavs_table = uav_placement(vertex_1, vertex_2, origin, altitude, cell_size, max_uavs, users_table, towers_table)
%UAV_PLACEMENT  Places UAVs on the plane to support cellular netoworks.
%   Uses a slightly modfied version of the Genetic Algorithm GLEON to find
%   out where to place UAVs in order to keep the network connected and
%   capable of providing the specified quality of service.
% Inputs:
%   vertex_1       : a 1-by-2 vector with latitude and longitude components
%                    of the first point that will be used to select the
%                    area of operation
%   vertex_2       : a 1-by-2 vector with latitude and longitude components
%                    of the second point that will be used to select the
%                    area of operation (diagonally opposed to the first)
%   origin         : a 1-by-3 vector with latitude, longitude and altitude
%                    of the point to use as the origin after the conversion
%                    to cartesian coordinates
%   altitude       : the average altitude of the area of interest,
%                    expressed in meters
%   cell_size      : the length of the side of the squares the area of
%                    interest should be divided into, expressed in meters;
%                    the center of each square will be considered as a
%                    possible location where to put a drone
%   max_uavs       : the maximum number of UAVs available for the
%                    deployment
%   users_table    : a table containing info about the users in the area of
%                    interest
%   towers_table   : a table containing info about the towers in the area
%                    of interest
% Outputs:
%   uavs_table   : a table with id and coordinates of each drone deployed
%                  in the area of interest

[x_range, y_range] = latlon2local([vertex_1(1), vertex_2(1)], [vertex_1(2), vertex_2(2)], altitude, origin);

positions_x = min(x_range) + cell_size / 2 : cell_size : max(x_range) - cell_size / 2;
positions_y = min(y_range) + cell_size / 2 : cell_size : max(y_range) - cell_size / 2;

[X, Y] = meshgrid(positions_x, positions_y);
positions = [X(:), Y(:)];

binary_length = ceil(log2(max_uavs));
permutation_length = length(positions);

options = optimoptions(@ga, 'PopulationType', 'custom', ...
                       'CreationFcn', {@creation, max_uavs, binary_length, permutation_length}, ...
                       'CrossoverFcn', {@crossover, max_uavs, binary_length, permutation_length},...
                       'MutationFcn', {@mutation, max_uavs, binary_length, permutation_length}, ...
                       'MaxGenerations', 500, ...
                       'PopulationSize', 25, ...
                       'MaxStallGenerations', 100, ...
                       'FunctionTolerance', 0, ...
                       'UseVectorized', true);

x = ga({@fitness, users_table, towers_table, max_uavs, positions}, 1, [], [], [], [], [], [], [], options);

uavs_table = uavs_table_from_chromosome(x{1}, positions);

end


function scores = fitness(x, users_table, towers_table, max_uav_number, positions)
%FITNESS  Evaluates the fitness of one or more individuals.
%   Assigns a cost to an individual or more by considering the number of
%   UAVs involved in the solution and how good their positioning is.
% Inputs:
%   x   : an individual or a vector of individuals of the population that
%         need evaluation
% Outputs:
%   scores   : a vector with a score for each individual evaluated within a
%              function call 

% Compute max consumed energy to use for normalization
TOWERS_MAX_ENERGY = sum(TOWER_K1 + towers_table.health .* (TOWER_K2 + TOWER_K3 * (TOWER_MAX_TRANSMIT_POWER - TOWER_MIN_TRANSMIT_POWER)));
UAVS_MAX_ENERGY = max_uav_number * (UAV_K1 + (UAV_K2 + UAV_K3 * (UAV_MAX_TRANSMIT_POWER - UAV_MIN_TRANSMIT_POWER)));

BASE_STATIONS_MAX_ENERGY = TOWERS_MAX_ENERGY + UAVS_MAX_ENERGY;

scores = zeros(size(x, 1), 1);

parfor i = 1 : size(x, 1)
    uavs_table = uavs_table_from_chromosome(x{i}, positions);
    
    base_stations_info_table = signal_based_association(users_table, towers_table, uavs_table, true);
    
    % Compute capital expense for UAVs
    capex = height(uavs_table) / max_uav_number;
    
    % Compute energy used by the configuration as a percentage of the
    % maximum
    towers_energy = sum(TOWER_K1 + base_stations_info_table.utilization(base_stations_info_table.type == TOWER_LABEL) .* (TOWER_K2 + TOWER_K3 * (TOWER_MAX_TRANSMIT_POWER - TOWER_MIN_TRANSMIT_POWER)));
    uavs_energy = sum(UAV_K1 + base_stations_info_table.utilization(base_stations_info_table.type == UAV_LABEL) .* (UAV_K2 + UAV_K3 * (UAV_MAX_TRANSMIT_POWER - UAV_MIN_TRANSMIT_POWER)));
    
    energy = (towers_energy + uavs_energy) / BASE_STATIONS_MAX_ENERGY;
    
    % Compute throughput penalty for the configuration
    violations = base_stations_info_table.health > 0 & base_stations_info_table.average_throughput < TARGET_THROUGHPUT;
    
    if any(violations)
        penalty = max(TARGET_THROUGHPUT - base_stations_info_table.average_throughput(violations)) / TARGET_THROUGHPUT;
    else
        penalty = 0;
    end
    
    scores(i) = 0.35 * capex + 0.25 * energy + 0.40 * penalty;
    
end

end


function population = creation(nvars, fitness_function, options, max_uav_number, binary_length, permutation_length)
%CREATION  Creates the initial population of chromosomes
%   Randomly defines the chromosomes to be used as the initial population
%   for the Genetic Algorithm.
% Inputs:
%   nvars              : the number of variables in each chromosome
%   fitness_function   : the fitness function used to evaluate chromosomes
%   options            : a structure created from optimoptions
% Outputs:
%   population   : a cell array containing the chromosomes of the initial
%                  population as structures with binary and permutation
%                  fields

population = cell(options.PopulationSize, 1);
first_positions = zeros(options.PopulationSize, 1);

for i = 1 : sum(options.PopulationSize)
    chromosome.binary = dec2bin(randi(max_uav_number), binary_length);

    while 1
        chromosome.permutation = randperm(permutation_length);

        if ~ismember(chromosome.permutation(1), first_positions)
            first_positions(i) = chromosome.permutation(1);
            break
        end
    end

    population{i} = chromosome;
end
    
end


function children = crossover(parents, options, nvars, fitness_function, scores, population, max_uav_number, binary_length, permutation_length)
%CROSSOVER  Defines the operations to occur during the crossover
%   Implements the One-Point Crossover for the binary part of the
%   chromosomes and the OX Crossover for the permutation part.
% Inputs:
%   parents            : parent chromosomes chosen by the selection function
%   options            : a structure created from optimoptions
%   nvars              : the number of variables in each chromosome
%   fitness_function   : the fitness function used to evaluate chromosomes
%   scores             : a vector with the scores of the current population
%   population         : the current population
% Outputs:
%   children   : a cell array with all the chromosomes obtained with the
%                crossover operations

children = cell(length(parents) / 2, 1);

for i = 1 : 2 : length(parents) / 2
    parent_1 = population{parents(i)};
    parent_2 = population{parents(i + 1)};
    
    % One-Point Crossover
    one_point_crossover_indexes = randperm(binary_length);
    
    for j = 1 : binary_length
        one_point_crossover_index = one_point_crossover_indexes(j);

        binary_1 = [parent_1.binary(1 : one_point_crossover_index - 1), ...
                    parent_2.binary(one_point_crossover_index : binary_length)];

        binary_2 = [parent_2.binary(1 : one_point_crossover_index - 1), ...
                    parent_1.binary(one_point_crossover_index : binary_length)];

        if bin2dec(binary_1) ~= 0 && bin2dec(binary_2) ~= 0 && bin2dec(binary_1) <= max_uav_number && bin2dec(binary_2) <= max_uav_number
           break
        end
    end
    
    % OX Crossover
    ox_crossover_indexes = zeros(1, 2); %= randi(permutation_length, 1, 2);
    ox_crossover_indexes(1) = randi(min([bin2dec(binary_1), bin2dec(binary_2)]));
    ox_crossover_indexes(2) = randi([ox_crossover_indexes(1) + 1, permutation_length]);
    
    ox_crossover_index_1 = min(ox_crossover_indexes);
    ox_crossover_index_2 = max(ox_crossover_indexes);

    permutation_1 = [parent_1.permutation(1 : ox_crossover_index_1 - 1), ...
                           parent_2.permutation(ox_crossover_index_1 : ox_crossover_index_2 - 1), ...
                           parent_1.permutation(ox_crossover_index_2 : permutation_length)];

    permutation_2 = [parent_2.permutation(1 : ox_crossover_index_1 - 1), ...
                           parent_1.permutation(ox_crossover_index_1 : ox_crossover_index_2 - 1), ...
                           parent_2.permutation(ox_crossover_index_2 : permutation_length)];

    children{i}.binary = binary_1;
    children{i}.permutation = permutation_1;

    children{i + 1}.binary = binary_2;
    children{i + 1}.permutation = permutation_2;
end

end


function children = mutation(parents, options, nvars, fitness_function, state, scores, population, max_uav_number, binary_length, permutation_length)
%MUTATION  Defines the operations to occur during the crossover
%   Implements the Bit-Flip operation for the binary part and the
%   Reciprocal Exchange for the permutation.
% Inputs:
%   parents            : parent chromosomes chosen by the selection function
%   options            : a structure created from optimoptions
%   nvars              : the number of variables in each chromosome
%   fitness_function   : the fitness function used to evaluate chromosomes
%   state              : a state structure used by the genetic algorithm
%   scores             : a vector with the scores of the current population
%   population         : the current population
% Outputs:
%   children   : a cell array with all the chromosomes resulting from the
%                mutation operations 

children = cell(length(parents), 1);

for i = 1 : length(children)
    child = population{parents(i)};
    
    bit_flip_indexes = randperm(binary_length);
    
    % Bit-Flip
    for j = 1 : binary_length
        binary = child.binary;
        
        bit_flip_index = bit_flip_indexes(j);
        
        if binary(bit_flip_index) == '0'
            binary(bit_flip_index) = '1';
        else
            binary(bit_flip_index) = '0';
        end
        
        if bin2dec(binary) > 0 && bin2dec(binary) <= max_uav_number
            child.binary = binary;
            break
        end
    end

    % Reciprocal Exchange
    exchange_pair = zeros(1, 2);
    
    exchange_pair(1) = randi(bin2dec(binary));
    exchange_pair(2) = randi([exchange_pair(1) + 1, permutation_length]);
    
    child.permutation(min(exchange_pair) : max(exchange_pair)) = fliplr(child.permutation(min(exchange_pair) : max(exchange_pair)));

    children{i} = child;
end

end


function uavs_table = uavs_table_from_chromosome(chromosome, positions)
%UAVS_TABLE_FROM_CHROMOSOME  Returns a UAV table from a chromosome.
%   This function translates the positioning info represented through a
%   chromosome into a table.
% Inputs:
%   chromosome   : the element of the population to be translated into a
%                  table
%   positions    : the vector containing the coordinates of the positions
%                  where UAVs can be placed
% Outputs:
%   uavs_table   : the table containing info about UAV placement expressed
%                  with cartesian coordinates

table_fields = [["id", "uint16"];
                ["x", "double"];
                ["y", "double"]];

uavs_used = bin2dec(chromosome.binary);
uavs_unique_positions = unique(chromosome.permutation, 'stable');

uavs_table = table('Size', [uavs_used, length(table_fields)], ...
                   'VariableNames', table_fields(:, 1), ...
                   'VariableTypes', table_fields(:, 2));

for i = 1 : uavs_used
    position = uavs_unique_positions(i);

    uavs_table(i, :).id = i;
    uavs_table(i, :).x = positions(position, 1);
    uavs_table(i, :).y = positions(position, 2);
end
    
end
