function plotTraining_choiceWorld()
% make overview plots across labs
% uses the gramm toolbox: https://github.com/piermorel/gramm
% Anne Urai, 2018

% grab all the data that's on Drive
addpath('~/Documents/code/npy-matlab//');
addpath(genpath('/Users/urai/Documents/code/analysis_IBL'));

if ispc,
    usr = getenv('USERNAME');
    homedir = getenv('USERPROFILE');
    datapath = fullfile(homedir, 'Google Drive');
elseif ismac,
    usr = getenv('USER');
    homedir = getenv('HOME');
    datapath = fullfile(homedir, 'Google Drive', 'IBL_DATA_SHARE');
end

set(groot, 'defaultaxesfontsize', 7, 'DefaultFigureWindowStyle', 'normal');
msz = 4;

%% overview
batches(1).name = {'choiceWorld'};
batches(1).mice =   sort({'IBL_34','IBL_2', 'IBL_4', 'IBL_5', 'IBL_7', 'IBL_33',  'IBL_35', 'IBL_36', 'IBL_37', ...
    'IBL_1', 'IBL_3', 'IBL_6', 'IBL_8', 'IBL_10', ...
    'IBL_13',  'IBL_14',  'IBL_15',  'IBL_16',  'IBL_17', ...
    'IBL_43', 'IBL_44', 'IBL_45', 'IBL_46', 'IBL_47'});

batches(2).name = {'choiceWorld'};
batches(2).mice = ({'LEW009', 'LEW010', 'LEW008'});
batches(2).mice = ({'438', '6812', '6814', '437'});
% , 

for bidx = length(batches):-1:2,
    for m = 1:length(batches(bidx).mice),
        
        close all;
        data_all = readAlf_allData(datapath, batches(bidx).mice{m});
        data_all.dayidx = data_all.dayidx - min(data_all.dayidx) + 1; % make sure the 1st day where there is data (not an empty folder) is dayidx 1
        
        if isempty(data_all), continue; end
        data_clean_all = data_all(data_all.inclTrials ~= 0, :);
        
        % =============================================== %
        % DETERMINE WHETHER (AND WHEN) THIS MOUSE IS TRAINED
        % =============================================== %
        
        % Decision: For each session, performance at high contrast > 80%.
        % Min trial per session 200.
        % On fitted data (over 3 session): |bias| < 16%, threshold > 19%, lapse < 0.2.
        
        % for each day, test the 2 top criteria
        useTrls = (abs(data_all.signedContrast) > 25 & data_all.inclTrials == 1);
        accuracy_crit = splitapply(@nanmean, 100*data_all.correct(useTrls), findgroups(data_all.dayidx(useTrls)));
        accuracy_crit = (accuracy_crit > 80);
        
        ntrials = splitapply(@numel, data_all.rt, findgroups(data_all.dayidx));
        ntrials_crit = (ntrials > 200);
        
        % additional criterion: all contrasts must be present
        allcontrasts = @(x) (numel(unique(abs(x(~isnan(x))))) == 6);
        contrasts_crit = splitapply(allcontrasts, data_all.signedContrast, findgroups(data_all.dayidx));
        
        % fit psychometric function over days
        fitPsych = @(x,y) {fitErf(x, y>0)};
        usedays = unique(data_all.dayidx);
        % usedays(usedays < 3) = [];
        psychfuncparams = nan(numel(usedays), 4);
        
        for d = usedays',
            if d >= 3,
                ThreeSessionTrls = (data_clean_all.dayidx >= d-2 & data_clean_all.dayidx <= d);
                psychfuncparams(find(d==usedays), :) = fitErf(data_clean_all.signedContrast(ThreeSessionTrls), (data_clean_all.response(ThreeSessionTrls)>0) );
            end
        end
        psychfuncparams(isnan(sum(psychfuncparams, 2)), :) = 0;
        
        % test if the criteria are true
        psychfunc_crit = (abs(psychfuncparams(:, 1)) < 16 & psychfuncparams(:, 2) > 19 ...
            & psychfuncparams(:, 3) < 0.2 & psychfuncparams(:, 4) < 0.2);
        has_learned = (accuracy_crit & ntrials_crit & contrasts_crit & psychfunc_crit);
        if any(has_learned),
            istrained = true;
            day_trained = find(has_learned == 1, 1, 'first');
        else
            istrained = false;
        end
        
        %         % =============================================== %
        %         % MAKE A FILE FOR NICK
        %         % =============================================== %
        %
        %         [gr, date] = findgroups(data_all.date);
        %         date = datestr(date, 'yyyy-mm-dd');
        %
        %         % fit the psychometric function separately for 2 biased conditions
        %         params = splitapply(fitPsych, data_all.signedContrast, data_all.response, gr);
        %         params = cat(1, params{:});
        %
        %         tab = array2table(params, 'variablenames', {'bias', 'slope', 'lapse_low', 'lapse_high'});
        %         tab.date = datestr(date, 'yyyy-mm-dd');
        %         writetable(tab, '~/Google Drive/IBL_DATA_SHARE/CSHL/fits/IBL_34_psychfuncfits.csv');
        %
        %         fitHistory = @(x,y) {glmfit(x, (y > 0), 'binomial')};
        %         resp = double(data_all.response); resp(resp == 0) = NaN;
        %         designM = [(data_all.signedContrast ./ 100), ...
        %             circshift(sign(data_all.signedContrast), 1), ...
        %             circshift(resp, 1), ...
        %             circshift(sign(data_all.correct-0.2), 1)];
        %         params = splitapply(fitHistory, designM, resp, gr);
        %         params = cat(2, params{:})';
        %
        %         tab = array2table(params, 'variablenames', {'bias', 'stimulus', 'answer_hist', 'choice_hist', 'reward_hist'});
        %         tab.date = datestr(date, 'yyyy-mm-dd');
        %         writetable(tab, '~/Google Drive/IBL_DATA_SHARE/CSHL/fits/IBL_34_psychfuncfits_trialhistory.csv');
        
        % =============================================== %
        % LEARNING CURVES
        % =============================================== %
        
        subplot(5,5,[1 2]);
        useTrls = (abs(data_all.signedContrast) > 50 & data_all.inclTrials == 1);
        errorbar(unique(data_all.dayidx(useTrls)), splitapply(@nanmean, 100*data_all.correct(useTrls), findgroups(data_all.dayidx(useTrls))), ...
            splitapply(@(x) (bootstrappedCI(x, 'mean', 'low')), 100*data_all.correct(useTrls), findgroups(data_all.dayidx(useTrls))), ...
            splitapply(@(x) (bootstrappedCI(x, 'mean', 'high')), 100*data_all.correct(useTrls), findgroups(data_all.dayidx(useTrls))), ...
            'capsize', 0, 'color', 'k', 'marker', 'o', 'markeredgecolor', 'w', 'markerfacecolor', 'k', 'markersize', msz);
        ylabel({'Performance (%)' 'on >50% contrast' 'repeat trials excluded'});
        set(gca, 'xtick', unique(data_all.dayidx));
        if numel(unique(data_all.dayidx)) > 20,
            xticks = unique([min(data_all.dayidx):5:max(data_all.dayidx) max(data_all.dayidx)]);
            set(gca, 'xtick', xticks');
        end
        box off; ylim([0 100]); xlim([0 max(data_all.dayidx)]);
        hline(50); hline(80);
        if istrained, vline(day_trained); end
        
        subplot(5,5,[6 7]); hold on;
        plot(unique(data_all.dayidx), ntrials, 'k', 'marker', 'o', 'markeredgecolor', 'w', 'markerfacecolor', 'k', 'markersize', msz);
        ylabel({'# Trials'});
        set(gca, 'xtick', unique(data_all.dayidx));
        if numel(unique(data_all.dayidx)) > 20,
            xticks = unique([min(data_all.dayidx):5:max(data_all.dayidx) max(data_all.dayidx)]);
            set(gca, 'xtick', xticks');
        end
        box off;  xlim([0 max(data_all.dayidx)]);
        hline(200);
        if istrained, vline(day_trained); end
        
        xlabel('Days');
        
        % TODO: INDICATE MONDAYS FOR TRIAL COUNT
        [gr, day] = findgroups(data_all.dayidx);
        daysofweek = splitapply(@unique, weekday(data_all.date), gr);
        p2 = plot(day(daysofweek == 2), ntrials(daysofweek == 2), 'ok', 'markeredgecolor', 'k', 'markerfacecolor', 'w', 'markersize', msz);
        %  annotation('textarrow', [day(find(daysofweek == 2, 1)) day(find(daysofweek == 2, 1))], ...
        %      [ntrials(find(daysofweek == 2, 1)) ntrials(find(daysofweek == 2, 1))-10],'String','Mondays');
        % legend(p2, 'Mondays', 'Location', 'NorthWest'); legend boxoff;
        ylim([0 max(get(gca, 'ylim'))]);
        
        % =============================================== %
        % PSYCHOMETRIC FUNCTION OVER DAYS
        % =============================================== %
        
        % fit psychometric function over days
        params   = splitapply(fitPsych, data_clean_all.signedContrast, data_clean_all.response, findgroups(data_clean_all.dayidx));
        params   = cat(1, params{:});
        
        subplot(9, 4,[3 4]); hold on;
        plot(unique(data_all.dayidx), params(:, 1), '-ko', 'markeredgecolor', 'w', 'markerfacecolor', 'k', 'markersize', msz);
        set(gca, 'xtick', unique(data_all.dayidx));
        ylabel('Bias'); ylim([-50 50]);
        hline(16); hline(-16);
        box off;  xlim([0 max(data_all.dayidx)]);
        set(gca, 'xcolor', 'w');
        if istrained, vline(day_trained); end
        
        subplot(9, 4,[7 8]); hold on;
        plot(unique(data_all.dayidx), params(:, 2), '-ko', 'markeredgecolor', 'w', 'markerfacecolor', 'k', 'markersize', msz);
        set(gca, 'xtick', unique(data_all.dayidx));
        ylabel('Threshold'); ylim([0 100]);
        hline(19);
        box off;  xlim([0 max(data_all.dayidx)]);
        set(gca, 'xcolor', 'w');
        if istrained, vline(day_trained); end
        
        subplot(9, 4,[11 12]); hold on;
        plot(unique(data_all.dayidx), params(:, 3), '-ko', 'markeredgecolor', 'w', 'markerfacecolor', 'k', 'markersize', msz);
        set(gca, 'xtick', unique(data_all.dayidx));
        ylabel({'Lapse' '(low)'}); ylim([0 1]);
        hline(0.2);
        box off;  xlim([-0.05 max(data_all.dayidx)]);
        set(gca, 'xcolor', 'w');
        if istrained, vline(day_trained); end
        
        subplot(9, 4,[15 16]); hold on;
        plot(unique(data_all.dayidx), params(:, 4), '-ko', 'markeredgecolor', 'w', 'markerfacecolor', 'k', 'markersize', msz);
    
        set(gca, 'xtick', unique(data_all.dayidx));
        if numel(unique(data_all.dayidx)) > 20,
            xticks = unique([min(data_all.dayidx):5:max(data_all.dayidx) max(data_all.dayidx)]);
            set(gca, 'xtick', xticks');
        end
        ylabel({'Lapse' '(high)'}); ylim([-0.05 1]);
        hline(0.2);
        box off;  xlim([0 max(data_all.dayidx)]);
        xlabel('Days');
        if istrained, vline(day_trained); end
        
        % ====================================================== %
        % IF THE MOUSE IS TRAINED (AND DOING BIASED BLOCKS),
        % SHOW THE PARAMETERS SEPARATELY FOR EACH BLOCK TYPE
        % ====================================================== %
        
        if numel(unique(data_clean_all.probabilityLeft(~isnan(data_clean_all.probabilityLeft)))) > 1,
            data_clean_all.probabilityLeft2 = sign(data_clean_all.probabilityLeft - 0.5);
            data_clean_all.probabilityLeft2(data_clean_all.probabilityLeft2 == 0) = NaN;
            [gr, bias, dayidx] = findgroups(data_clean_all.probabilityLeft2, data_clean_all.dayidx);
            
            % fit the psychometric function separately for 2 biased conditions
            params = splitapply(fitPsych, data_clean_all.signedContrast, (data_clean_all.response > 0), gr);
            params = cat(1, params{:});
            
            colors = linspecer(numel(unique(bias)));
            for b = [-1 1],
                for p = 1:4,
                    subplot(9, 4, [4*p-1:4*p]);
                    plot(dayidx(bias == b), ...
                        params(bias == b, p), '-o', 'markeredgecolor', ...
                        'w', 'markerfacecolor', colors((b > 0) + 1, :), 'color', colors((b > 0) + 1, :), 'markersize', msz-1);
                end
            end
        end
        
        % =============================================== %
        % OVERVIEW OF LAST 3 DAYS
        % =============================================== %
        
        days = sort(unique(data_all.dayidx_rev));
        if length(days) <= 2,
            continue;
        end
        days = days(end-2:end);
        for didx = 1:length(days),
            
            % use only the data for this day
            data_clean  = data_clean_all(data_clean_all.dayidx_rev == days(didx), :);
            data        = data_all(data_all.dayidx_rev == days(didx), :);
            
            % PSYCHOMETRIC AND CHRONOMETRIC FUNCTION
            subplot(4,4,didx+8);
            set(gca,'ColorOrder', [0.7 0.7 0.7; 0 0 0]); hold on;
            
            % right y-axis: chronometric function
            yyaxis left;
            errorbar(unique(data_clean.signedContrast(~isnan(data_clean.signedContrast))), ...
                splitapply(@nanmedian, data_clean.rt, findgroups(data_clean.signedContrast)), ...
                splitapply(@(x) (bootstrappedCI(x, 'median', 'low')), data_clean.rt, findgroups(data_clean.signedContrast)), ...
                splitapply(@(x) (bootstrappedCI(x, 'median', 'high')), data_clean.rt, findgroups(data_clean.signedContrast)), ...
                'capsize', 0, 'marker', 'o', 'markerfacecolor', 'w', 'markersize', 2);
            
            if didx == 1, ylabel('RT (s)'); end
            xlim([-105 105]);
            
            % add psychometric function
            yyaxis right;
            psychFuncPred = @(x, mu, sigma, gamma, lambda) gamma + (1 - gamma - lambda) * (erf( (x-mu)/sigma ) + 1 )/2;
            
            data_clean.probabilityLeft = roundn(data_clean.probabilityLeft, -2);
            leftProbs = unique(data_clean.probabilityLeft(~isnan(data_clean.probabilityLeft)));
            if isempty(leftProbs), data_clean.probabilityLeft(:) = 0.5; leftProbs = 0.5; end
            colors = linspecer(numel(leftProbs));
            for lp = 1:length(leftProbs),
                tmpdata = data_clean(data_clean.probabilityLeft == leftProbs(lp), :);
                errorbar(unique(tmpdata.signedContrast(~isnan(tmpdata.signedContrast))), ...
                    splitapply(@nanmean, tmpdata.response > 0, findgroups(tmpdata.signedContrast)), ...
                    splitapply(@(x) (bootstrappedCI(x, 'mean', 'low')), tmpdata.response > 0, findgroups(tmpdata.signedContrast)), ...
                    splitapply(@(x) (bootstrappedCI(x, 'mean', 'high')), tmpdata.response > 0, findgroups(tmpdata.signedContrast)), ...
                    'color', colors(lp, :), 'capsize', 0, 'marker', 'o', 'markerfacecolor', 'w', 'markersize', 2, 'linestyle', 'none');
                
                [mu, sigma, gamma, lambda] = fitErf(tmpdata.signedContrast, tmpdata.response > 0);
                y = psychFuncPred(linspace(min(tmpdata.signedContrast), max(tmpdata.signedContrast), 100), ...
                    mu, sigma, gamma, lambda);
                plot(linspace(min(tmpdata.signedContrast), max(tmpdata.signedContrast), 100), y, '-', 'color', colors(lp, :));
            end
            
            xlabel('Contrast (%)'); if didx == 3, ylabel('P(right)'); end
            box off;
            xlim([-105 105]); ylim([0 1]); % offsetAxes;
            set(gca, 'yminortick', 'on', 'xminortick', 'on');
            
            %             title({sprintf('%s', datestr(unique(data_clean.date))), ...
            %                 sprintf('\\mu %.2f \\sigma %.2f \\gamma %.2f \\lambda %.2f', mu, sigma, gamma, lambda)}, ...
            %                 'fontweight', fontweigth, 'color', titlecol); % show date
            %
            title(sprintf('%s', datestr(unique(data_clean.date))), ...
                'fontweight', 'normal'); % show date
            
            % RTs over time
            subplot(4,4,didx+12); hold on; colormap(linspecer(2));
            s3 = scatter(data.trialNum(data.inclTrials == 0), data.rt(data.inclTrials ==0), 3, '.k');
            s1 = scatter(data.trialNum(data.inclTrials == 1 & data.correct == 1), data.rt(data.inclTrials == 1 & data.correct == 1), 3, '.b');
            s2 = scatter(data.trialNum(data.inclTrials == 1 & data.correct == 0), data.rt(data.inclTrials == 1 & data.correct == 0), 3, '.r');
            
            xlabel('# trials');
            if didx == 1, ylabel('RT (s)'); end
            axis tight; xlim([-2 max(data.trialNum)]);
            set(gca, 'yscale', 'log');
            ylim([-1000 max(get(gca, 'ylim'))]);
            set(gca, 'yticklabel', sprintfc('%.1f', get(gca, 'ytick')));
            
            if didx == length(days),
                lh = legend([s1 s2 s3], {'correct', 'error', 'repeat'});
                lh.Box = 'off';
                lh.Position(1) = lh.Position(1) + 0.15;
            end
        end
        
        % =============================================== %
        % SAVE
        % =============================================== %
        
        switch istrained
            case 1
                trainedStr = sprintf('trained from day %d', day_trained);
            case 0
                trainedStr = 'not trained';
        end
        titlestr = sprintf('Lab %s, task %s, mouse %s, %s', data.Properties.UserData.lab, ...
            regexprep(batches(bidx).name{1}, '_', ' '), regexprep(batches(bidx).mice{m}, '_', ''), trainedStr);
        try suptitle(titlestr); end
        
        foldername = fullfile(getenv('HOME'), 'Google Drive', 'Rig building WG', ...
            'DataFigures', 'BehaviourData_Weekly', '2018-10-29');
        if ~exist(foldername, 'dir'), mkdir(foldername); end
        print(gcf, '-dpdf', fullfile(foldername, sprintf('%s_%s_%s_%s.pdf', datestr(now, 'yyyy-mm-dd'), ...
            data.Properties.UserData.lab, batches(bidx).name{1}, batches(bidx).mice{m})));
        
    end
end
end

