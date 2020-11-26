function towers_table = natural_disaster(center, extension, destruction_probability, damage_probability, towers_table)
%NATURAL_DISASTER  Introduces a worsening factor to the signal of the
%                  towers inside a given circular area.
%   This function is used to simulate the effectcs of a natural disaster on
%   the communication infrastructure by randomly altering the packet loss
%   of all the towers in a given circular area specified by the function
%   parameters.
% Inputs:
%   center                    : a 1-by-2 vector with x and y coordinates of
%                               the center of the area affected by the
%                               disaster
%   extension                 : the radius of the disaster expressed in
%                               meters
%   destruction_probability   : the probability that a tower in the area
%                               affected by the disaster is completely
%                               offline
%   damage_probability        : the probability that a tower in the area
%                               affected by the disaster gets some damage
%                               (must be bigger than the previous one)
%   towers_table              : the table with all the towers being
%                               considered
% Output:
%   towers_table   : the table with all the towers info updated after the
%                    disaster

worsening = zeros(height(towers_table), 1);

min_worsening = 0;
max_worsening = 0.5;

distances = sqrt((center(1) - towers_table.x) .^ 2 + (center(2) - towers_table.y) .^ 2);
towers_affected = distances <= extension;

probabilities = rand(height(towers_table, 1));

towers_destroyed = probabilities <= destruction_probability;
towers_damaged = probabilities <= damage_probability;

worsening(towers_affected & towers_damaged) = min_worsening + (max_worsening - min_worsening) .* rand(sum(towers_affected & towers_damaged), 1);
worsening(towers_affected & towers_destroyed) = ones(sum(towers_affected & towers_destroyed), 1);

towers_table(:, :).worsening = worsening;

end
