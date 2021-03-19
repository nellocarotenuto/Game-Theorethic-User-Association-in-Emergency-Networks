function game_changes_history_plot(changes_history)
%GAME_CHANGES_HISTORY Plots the number of changes at each iteration of the game.

% Set figure name and plot title
figure('Name', 'Strategy changes during the game');

hold on
ylabel('Strategy changes');
xlabel('Round');

xlim([0.5, length(changes_history) + 0.5]);
ylim([-0.8, max(changes_history) + 0.8]);

plot(1 : length(changes_history), changes_history, 'Color', '#e53626', 'LineWidth', 1);

end
