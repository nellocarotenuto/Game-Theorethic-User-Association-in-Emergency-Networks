function towers_table = manmade_disaster(destruction_probability, damage_probability, towers_table)
%MANMADE_DISASTER  Introduces a worsening factor to the signal of some of
%                  the towers chosen randomly.
% Inputs:
%   destruction_probability   : the probability that a tower is completely
%                               offline
%   damage_probability        : the probability that a tower gets some
%                               damage (must be bigger than the previous
%                               one)
%   towers_table              : the table with all the towers being
%                               considered
% Output:
%   towers_table   : the table with all the towers info updated after the
%                    disaster

worsening = zeros(height(towers_table), 1);

min_worsening = 0;
max_worsening = 0.5;

probabilities = rand(height(towers_table, 1));

towers_destroyed = probabilities <= destruction_probability;
towers_damaged = probabilities <= damage_probability;

worsening(towers_damaged) = min_worsening + (max_worsening - min_worsening) .* rand(sum(towers_damaged), 1);
worsening(towers_destroyed) = ones(sum(towers_destroyed), 1);

towers_table(:, :).worsening = worsening;

end

