function [total_energy, towers_energy, uavs_energy] = base_stations_consumed_energy(base_stations_type, base_stations_utilization)
%BASE_STATIONS_CONSUMED_ENERGY Computes the energy consumed by the base stations.
% Inputs:
%   base_stations_type        : a vector of labels for each base station
%                               considered
%   base_stations_utilization : a vector of utilization percentages for
%                               each base station considered
% Outputs:
%   total_energy  : the total amount of energy consumed expressed in Watts
%   towers_energy : the amount of energy consumed by the towers
%   uavs_energy   : the amount of energy consumed by the UAVs deployed

towers_energy = sum(TOWER_K1 + base_stations_utilization(base_stations_type == TOWER_LABEL) .* (TOWER_K2 + TOWER_K3 * (TOWER_MAX_TRANSMIT_POWER - TOWER_MIN_TRANSMIT_POWER)));
uavs_energy = sum(UAV_K1 + base_stations_utilization(base_stations_type == UAV_LABEL) .* (UAV_K2 + UAV_K3 * (UAV_MAX_TRANSMIT_POWER - UAV_MIN_TRANSMIT_POWER)));

total_energy = towers_energy + uavs_energy;

end
