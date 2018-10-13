function citricAcid_ntrials

data = readAlf_allData(fullfile(getenv('HOME'), 'Google Drive', 'IBL_DATA_SHARE'), ...
    {'IBL_2', 'IBL_4', 'IBL_5', 'IBL_7', 'IBL_33', 'IBL_34', 'IBL_35', 'IBL_36', 'IBL_37', ...
    'IBL_1', 'IBL_3', 'IBL_6', 'IBL_13',  'IBL_14',  'IBL_15',  'IBL_16',  'IBL_17', ...
    'IBL_10', 'IBL_8'});

foldername = fullfile(getenv('HOME'), 'Google Drive', 'Rig building WG', ...
    'DataFigures', 'BehaviourData_Weekly', '2018-10-09');

% grab only those dates that are immediately before and after citric acid
% or normal water intervention

data = data(ismember(datenum(data.date), datenum({'2018-09-24', '2018-10-01', '2018-10-09'})), :);
[~, data.weekday] = weekday(datenum(data.date));
data.weekday = cellstr(data.weekday);

data.water = data.animal;
data.water(datenum(data.date) <= datenum('2018-09-24')) = {'1ml/day'};
data.water(datenum(data.date) == datenum('2018-10-01')) = {'CA 5% in hydrogel'};
data.water(datenum(data.date) == datenum('2018-10-09')) = {'CA 2% in water'};
data = data(:, {'water', 'trialNum', 'animal', 'weekday', 'date'});

data_tmp = data(:, {'trialNum', 'animal', 'date'});
data_mat = unstack(data_tmp, {'trialNum'}, 'date', 'AggregationFunction', @max);

% remove two mice that already got CA hydrogel a week early
data_mat{ismember(data_mat.animal, {'IBL_10', 'IBL_8'}), 2} = NaN;

% separate out the mice that got sucrose on the 9th of October in the rig
sucrosetrials = data_mat{ismember(data_mat.animal, {'IBL_33', 'IBL_13'}), 4};
data_mat{ismember(data_mat.animal, {'IBL_33', 'IBL_13'}), 5} = NaN;

data_mat = data_mat{:, 2:end};
xvars = repmat([1 2 3 4], [size(data_mat, 1) 1]);

%% BARGRAPH WITH SCATTER
set(groot, 'defaultaxesfontsize', 7, 'DefaultFigureWindowStyle', 'normal');

close all; 
subplot(3,3,[1]); hold on;
s = scatter(xvars(:), data_mat(:), 10,  [0.5 0.5 0.5], 'o', 'jitter', 'on');
scatter([3 3], sucrosetrials, 15, [0.5 0.5 0.5], 'd', 'jitter', 'on');

% different errorbars
colors = linspecer(4);
for i = 1:4,
    e{i} = errorbar(i, nanmean(data_mat(:, i)), nanstd(data_mat(:, i)), ...
        'o', 'color',  colors(i, :), 'markerfacecolor', 'w', 'markeredgecolor', colors(i, :), 'linewidth', 1, 'capsize', 0);
end
xlim([0.5 3.5]);


set(gca, 'xtick', 1:3, 'xticklabel', unique(data.water, 'stable'), 'xticklabelrotation', -20);
title('Water restriction regimes');

ylabel({'Number of trials' 'on Monday (CSHL)'});
offsetAxes;
%subplot(333); axis off;
% 
% % add the pairs
% subplot(444);
% scatter(data_mat(:, 2), data_mat(:, 4), 15, [0.5 0.5 0.5], 'o');
% xlabel('Trials after 1ml/day'); ylabel('Trials after 2% CA water');
% axis square;
% axisEqual; r = refline(1,0); r.Color = 'k'; r.LineWidth = 0.5;
% %offsetAxes;

tightfig;
print(gcf, '-dpdf', fullfile(foldername, 'citricAcid_trialCounts_CSHL.pdf'));
print(gcf, '-dpdf', '/Users/urai/Google Drive/2018 Postdoc CSHL/CitricAcid/citricAcid_trialCounts_CSHL.pdf');

% 
% %% pivot the table
% data2 = unstack(data, {'trialNum'}, 'weekday', 'AggregationFunction', @max);
% 
% % plot
% close all;
% g = gramm('x', data2.Fri, 'y', data2.Mon, 'color', data2.water);
% g.geom_point()
% g.geom_abline('slope', 1, 'intercept', 0, 'style', 'k-')
% g.set_names('x', '# Trials on Friday', 'y', '# Trials on Monday', 'color', 'Regime');
% g.axe_property('xlim', [150 1000], 'ylim', [150 1000]);
% 
% %g.stat_summary('type', 'ci', 'geom', 'black_errorbar');
% g.stat_glm()
% g.draw()
% 
% print(gcf, '-dpdf', fullfile(foldername, 'citricAcid_CSHL.pdf'));


end

