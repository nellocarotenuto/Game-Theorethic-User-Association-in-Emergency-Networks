function throughput_distribution_plot(throughput_distributions, labels)
%THROUGHPUT_DISTRIBUTION_PLOT Shows throughput distributions against each other in a box and whisker plot.
% Inputs:
%   throughput_distributions   : a matrix with throughput distributions in
%                                each column
%   labels                     : a cell array of labels for each
%                                distribution to plot

% Set figure name and plot title
figure('Name', 'Throughput Distribution');

hold on

ax = gca;

xlabel('Throughput');

boxplot(throughput_distributions, 'Labels', labels, 'orientation', 'horizontal');

ax.XAxis.Scale = "log";
hold off

end

