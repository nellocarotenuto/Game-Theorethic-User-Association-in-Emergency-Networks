function capacity = channel_capacity(received_power, total_received_power)
%CHANNEL_CAPACITY Computes the channel capacity according to Shannon's law.
% Inputs:
%   received_power         : the amount of power received by the target
%                            from the source
%   total_received_power   : the total amount of power received by the
%                            target from every base station in the area,
%                            including the source
% Outputs:
%   capacity   : the capacity of the channel between the source and the
%                target

capacity = BANDWIDTH * log2(1 + (received_power ./ (AWGN * BANDWIDTH + (total_received_power - received_power) * LOSS)));

end
