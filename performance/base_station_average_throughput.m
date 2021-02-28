function average_throughput = base_station_average_throughput(channel_capacities, number_of_users, utilization)
%BASE_STATION_AVERAGE_THROUGHPUT Computes the average throughput of a base station.
% Inputs:
%   channel_capacities   : the capacities of each channel between the base
%                          station and its associated users
%   number_of_users      : the amount of users associated to the base
%                          station
%   utilization          : the utilization factor of the base station
% Outputs:
%   average_throughput   : the average throughput of base station's users

average_throughput = sum(channel_capacities) / number_of_users ^ 2 * utilization;

end
