function received_power = received_power(transmit_power, distance)
%RECEIVED_POWER  Computes the received power at a certain distance from the source.
% Inputs:
%   transmit_power   : the power at which the source is transmitting,
%                      expressed in Watts
%   distance         : the distance at which the target is from the source,
%                      expressed in meters
% Outputs:
%   received_power   : the amount of power received by the target from the
%                      source

low_distances = distance < 10;
distance(low_distances) = 10;

received_power = transmit_power .* GAIN .* (10 ./ distance) .^ 3;

end
