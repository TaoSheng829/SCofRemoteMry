function [results] = cross_validated_sigmoid_fitting(data, k_folds, make_plots)
% cross_validated_sigmoid_fitting: Fit a sigmoid curve to data using k‑fold cross‑validation.
%   This function fits a four‑parameter logistic (sigmoid) model to time‑series
%   data, estimates the 50% transition point (t50), and evaluates model stability
%   via k‑fold cross‑validation. It computes performance metrics (MSE, R²),
%   provides confidence intervals for t50, and optionally generates diagnostic plots.
%
%   Inputs:
%       data      : N×2 matrix where column 1 = time (x‑axis), column 2 = measurement (y‑axis).
%       k_folds   : (Optional) Number of folds for cross‑validation (default: 5).
%       make_plots: (Optional) Logical flag to generate figures (default: true).
%
%   Output:
%       results   : Structure containing:
%           final_params   : Final fitted parameters [lower_asym, upper_asym, growth_rate, t50].
%           final_t50      : t50 from full‑data fit.
%           t50_mean       : Mean t50 across folds.
%           t50_std        : Standard deviation of t50 across folds.
%           t50_ci         : 95% confidence interval of t50 (percentile‑based).
%           t50_cv         : Coefficient of variation (%) of t50.
%           all_t50        : Vector of t50 values from each fold.
%           mse_scores     : Mean squared error for each fold.
%           r2_scores      : R² value for each fold.
%           all_params     : 4×k_folds matrix of fitted parameters per fold.
%
%   The sigmoid model: y = p1 + (p2‑p1) ./ (1 + exp(‑p3*(x‑p4)))
%       p1 = lower asymptote, p2 = upper asymptote,
%       p3 = growth rate (slope parameter), p4 = t50 (inflection point).

    % ---- Input validation and default values ----
    if nargin < 2
        k_folds = 5;
    end
    if nargin < 3
        make_plots = true;
    end

    % Extract time and measurement columns
    t = data(:, 1);
    y = data(:, 2);

    % ---- Define the sigmoid function (four‑parameter logistic) ----
    sigmoid_func = @(p, x) p(1) + (p(2) - p(1)) ./ (1 + exp(-p(3) * (x - p(4))));
    % Parameter meanings: p(1)=lower asymptote, p(2)=upper asymptote,
    %                     p(3)=growth rate, p(4)=50% transition point (t50).

    % ---- Initial parameter guesses ----
    initial_params = [min(y), max(y), 0.1, median(t)];

    % ---- Parameter bounds ----
    lb = [min(y) - std(y), min(y), 0, min(t)];   % Lower bounds
    ub = [max(y), max(y) + std(y), 10, max(t)];  % Upper bounds

    % ---- Setup cross‑validation ----
    n = length(t);
    fold_size = floor(n / k_folds);

    % Preallocate storage for fold results
    all_t50 = zeros(k_folds, 1);
    all_params = zeros(k_folds, 4);
    mse_scores = zeros(k_folds, 1);
    r2_scores = zeros(k_folds, 1);

    % Generate cross‑validation indices (stratified random)
    cv_indices = crossvalind('Kfold', n, k_folds);

    % ---- Main loop: k‑fold cross‑validation ----
    for fold = 1:k_folds
        % Split data into training and test sets
        test_mask = (cv_indices == fold);
        train_mask = ~test_mask;

        train_t = t(train_mask);
        train_y = y(train_mask);
        test_t = t(test_mask);
        test_y = y(test_mask);

        % Fit sigmoid to training set using nonlinear least squares
        options = optimoptions('lsqcurvefit', ...
            'Display', 'off', ...
            'Algorithm', 'trust-region-reflective');

        [params, resnorm] = lsqcurvefit(sigmoid_func, initial_params, ...
            train_t, train_y, lb, ub, options);

        % Predict on test set
        predicted_y = sigmoid_func(params, test_t);

        % Compute performance metrics
        mse_scores(fold) = mean((test_y - predicted_y).^2);
        ss_tot = sum((test_y - mean(test_y)).^2);
        ss_res = sum((test_y - predicted_y).^2);
        r2_scores(fold) = 1 - ss_res / ss_tot;

        % Store parameters and t50
        all_params(fold, :) = params;
        all_t50(fold) = params(4);

        % ---- Optional: plot each fold's results ----
        if make_plots
            figure(1);
            subplot(2, ceil(k_folds/2), fold);
            scatter(test_t, test_y, 40, 'r', 'filled', 'DisplayName', 'Test data');
            hold on;
            scatter(train_t, train_y, 20, 'b', 'DisplayName', 'Train data');

            % Plot fitted sigmoid curve
            t_fine = linspace(min(t), max(t), 200);
            y_fine = sigmoid_func(params, t_fine);
            plot(t_fine, y_fine, 'k-', 'LineWidth', 2, 'DisplayName', 'Fitted sigmoid');

            % Mark the t50 point on the curve
            t50 = params(4);
            y50 = sigmoid_func(params, t50);
            plot(t50, y50, 'g*', 'MarkerSize', 15, 'LineWidth', 2, ...
                'DisplayName', sprintf('t_{50}=%.2f', t50));

            xlabel('Time');
            ylabel('Measurement');
            title(sprintf('Fold %d (R²=%.3f)', fold, r2_scores(fold)));
            legend('Location', 'best');
            grid on;
            hold off;
        end
    end

    % ---- Final fit using all data ----
    options = optimoptions('lsqcurvefit', ...
        'Display', 'off', ...
        'Algorithm', 'trust-region-reflective');
    [final_params, ~] = lsqcurvefit(sigmoid_func, initial_params, ...
        t, y, lb, ub, options);
    final_t50 = final_params(4);

    % ---- Compute statistics across folds ----
    t50_mean = mean(all_t50);
    t50_std = std(all_t50);
    t50_ci = [prctile(all_t50, 2.5), prctile(all_t50, 97.5)];   % 95% bootstrap‑like CI
    results.t50_cv = 100 * t50_std / t50_mean;                   % Coefficient of variation (%)

    % ---- Display summary results to console ----
    fprintf('\n======= CROSS-VALIDATION RESULTS =======\n');
    fprintf('Number of folds: %d\n', k_folds);
    fprintf('Average MSE: %.4f ± %.4f\n', mean(mse_scores), std(mse_scores));
    fprintf('Average R²: %.4f ± %.4f\n', mean(r2_scores), std(r2_scores));
    fprintf('\n50%% transition point (t50) analysis:\n');
    fprintf('Final t50 (full data): %.4f\n', final_t50);
    fprintf('Mean t50 (CV): %.4f ± %.4f\n', t50_mean, t50_std);
    fprintf('95%% CI: [%.4f, %.4f]\n', t50_ci(1), t50_ci(2));
    fprintf('CV stability (t50_std/mean): %.2f%%\n', 100 * t50_std / t50_mean);

    % ---- Optional: generate comprehensive summary figures ----
    if make_plots
        figure(2);
        set(gcf, 'Position', [100, 100, 1200, 500]);

        % Subplot 1: Data fit and t50 marking
        subplot(1, 3, 1);
        scatter(t, y, 50, 'filled', 'DisplayName', 'Data');
        hold on;

        % Plot final fit curve
        t_fine = linspace(min(t), max(t), 300);
        y_fine = sigmoid_func(final_params, t_fine);
        plot(t_fine, y_fine, 'r-', 'LineWidth', 3, 'DisplayName', 'Final fit');

        % Mark all CV t50 values on the curve
        for i = 1:k_folds
            t50_cv = all_t50(i);
            y50_cv = sigmoid_func(final_params, t50_cv);
            plot(t50_cv, y50_cv, 'bo', 'MarkerSize', 8, 'LineWidth', 1.5);
        end

        % Mark final t50
        y50_final = sigmoid_func(final_params, final_t50);
        plot(final_t50, y50_final, 'g*', 'MarkerSize', 20, 'LineWidth', 3, ...
            'DisplayName', sprintf('Final t_{50}=%.3f', final_t50));

        xlabel('Time');
        ylabel('Measurement');
        title('Sigmoid Fit with Cross-Validation');
        legend('Location', 'best');
        grid on;
        hold off;

        % Subplot 2: Histogram of t50 values
        subplot(1, 3, 2);
        histogram(all_t50, 'FaceColor', [0.2, 0.6, 0.8], 'EdgeColor', 'k');
        hold on;
        plot([final_t50, final_t50], ylim, 'r-', 'LineWidth', 3, 'DisplayName', 'Final t50');
        plot([t50_ci(1), t50_ci(1)], ylim, 'g--', 'LineWidth', 2, 'DisplayName', '95% CI');
        plot([t50_ci(2), t50_ci(2)], ylim, 'g--', 'LineWidth', 2);

        xlabel('t50 values');
        ylabel('Frequency');
        title(sprintf('t50 Distribution (CV)\nMean: %.3f ± %.3f', t50_mean, t50_std));
        legend('Location', 'best');
        grid on;

        % Subplot 3: Performance per fold (R²)
        subplot(1, 3, 3);
        bar(1:k_folds, r2_scores, 'FaceColor', [0.8, 0.2, 0.2]);
        hold on;
        plot(xlim, [mean(r2_scores), mean(r2_scores)], 'k--', 'LineWidth', 2, ...
            'DisplayName', sprintf('Mean R²=%.3f', mean(r2_scores)));

        xlabel('Fold number');
        ylabel('R² score');
        title('Cross-Validation Performance');
        legend('Location', 'best');
        grid on;
        ylim([0, 1]);

        % Print detailed parameter statistics to console
        fprintf('\n======= MODEL PARAMETERS =======\n');
        fprintf('Parameter\tMean ± Std\t\t95%% CI\n');
        fprintf('----------------------------------------\n');
        param_names = {'Lower asymptote', 'Upper asymptote', 'Growth rate', 't50'};

        for i = 1:4
            param_mean = mean(all_params(:, i));
            param_std = std(all_params(:, i));
            param_ci = [prctile(all_params(:, i), 2.5), prctile(all_params(:, i), 97.5)];
            fprintf('%s\t%.3f ± %.3f\t[%.3f, %.3f]\n', ...
                param_names{i}, param_mean, param_std, param_ci(1), param_ci(2));
        end

        % ---- Store all results in output structure ----
        results.final_t50 = final_t50;
        results.t50_mean = t50_mean;
        results.t50_std = t50_std;
        results.t50_ci = t50_ci;
        results.all_t50 = all_t50;
        results.mse_scores = mse_scores;
        results.r2_scores = r2_scores;
        results.final_params = final_params;
        results.all_params = all_params;

        % Also save to base workspace for easy access
        assignin('base', 'cv_results', results);
        fprintf('\nResults saved to workspace variable "cv_results"\n');
    end
end