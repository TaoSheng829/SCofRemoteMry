function [p_value, results] = permutation_test_t50_stability(data, k_folds, n_permutations)
% permutation_test_t50_stability: Assess whether the cross-validated t50
%   coefficient of variation (CV) is statistically significant.
%
%   This function tests the null hypothesis that the observed instability
%   of the t50 estimate (as measured by CV across cross‑validation folds)
%   is merely due to random sampling fluctuations. It generates a null
%   distribution by permuting residuals from the final fitted sigmoid,
%   recomputes t50 CV for each permuted dataset, and compares the observed
%   CV to this null distribution.
%
%   Inputs:
%       data           : N×2 matrix [time, measurement].
%       k_folds        : Number of folds for cross‑validation (passed to
%                        cross_validated_sigmoid_fitting).
%       n_permutations : Number of permutation iterations.
%
%   Outputs:
%       p_value        : Proportion of permutations with CV ≥ observed CV.
%       results        : Structure containing:
%           observed_cv   : Observed t50 CV (%).
%           null_mean     : Mean of null distribution (%).
%           null_std      : Standard deviation of null distribution (%).
%           null_95ci     : 95% percentile‑based confidence interval (%).
%           p_value       : Same as output.
%           null_distribution: Vector of all permutation CV values (fraction).
%
%   Algorithm:
%       1. Fit sigmoid to original data and compute observed t50 CV via CV.
%       2. Generate ideal (noise‑free) predictions from the final fit.
%       3. Compute residuals and their standard deviation.
%       4. For each permutation, shuffle residuals, add to ideal curve,
%          refit sigmoid to the permuted data, and compute t50 CV.
%       5. Compute p‑value as the fraction of permutations with CV ≥ observed.
%       6. Generate histogram and ECDF plots of the null distribution.

    % ---- Step 1: Compute observed CV from original data ----
    % Run cross‑validation once without plotting (make_plots = false)
    original_results = cross_validated_sigmoid_fitting(data, k_folds, false);
    observed_t50_cv = original_results.t50_cv / 100;  % Convert percentage to fraction

    % ---- Step 2: Generate null hypothesis data ----
    % Null hypothesis: data arise from a single deterministic sigmoid with
    % additive noise (i.e., no extra variability beyond residual noise).
    t = data(:, 1);
    y = data(:, 2);

    % Define sigmoid function (same as in the fitting routine)
    sigmoid_func = @(p, x) p(1) + (p(2) - p(1)) ./ (1 + exp(-p(3) * (x - p(4))));
    params = original_results.final_params;   % Parameters from full‑data fit

    % Generate ideal (noise‑free) predictions
    y_ideal = sigmoid_func(params, t);

    % Estimate noise level from residuals
    residuals = y - y_ideal;
    noise_std = std(residuals);

    % ---- Step 3: Permutation loop ----
    perm_cv_values = zeros(n_permutations, 1);

    for perm = 1:n_permutations
        % Method 1: Shuffle residuals (preserves time structure of noise)
        shuffled_residuals = residuals(randperm(length(residuals)));
        permuted_y = y_ideal + shuffled_residuals;

        % Alternative: generate new Gaussian noise (commented out)
        % permuted_y = y_ideal + noise_std * randn(size(y));

        % Create permuted dataset
        permuted_data = [t, permuted_y];

        % Compute t50 CV on permuted data (suppress plots)
        try
            perm_results = cross_validated_sigmoid_fitting(permuted_data, k_folds, false);
            perm_cv_values(perm) = perm_results.t50_cv / 100;   % Store as fraction
        catch
            % If fitting fails (e.g., non‑convergence), mark as NaN and continue
            perm_cv_values(perm) = NaN;
        end
    end

    % Remove any failed fits (NaN values)
    perm_cv_values = perm_cv_values(~isnan(perm_cv_values));

    % ---- Step 4: Compute p‑value ----
    % p = proportion of permutations with CV ≥ observed CV (one‑sided test)
    p_value = sum(perm_cv_values >= observed_t50_cv) / length(perm_cv_values);

    % ---- Step 5: Compile results structure ----
    results.observed_cv = observed_t50_cv * 100;                    % As percentage
    results.null_mean = mean(perm_cv_values) * 100;
    results.null_std = std(perm_cv_values) * 100;
    results.null_95ci = [prctile(perm_cv_values, 2.5), prctile(perm_cv_values, 97.5)] * 100;
    results.p_value = p_value;
    results.null_distribution = perm_cv_values;

    % ---- Step 6: Visualize results ----
    figure('Position', [100, 100, 1000, 400]);

    % Panel 1: Histogram of null distribution with observed value
    subplot(1, 2, 1);
    histogram(perm_cv_values * 100, 30, 'FaceColor', [0.8, 0.8, 1], ...
        'EdgeColor', 'k', 'Normalization', 'probability');
    hold on;
    plot([results.observed_cv, results.observed_cv], ylim, 'r-', 'LineWidth', 3);
    plot([results.null_mean, results.null_mean], ylim, 'b--', 'LineWidth', 2);

    xlabel('t50 CV (%)');
    ylabel('Probability');
    title(sprintf('Permutation Test for t50 CV Stability\np = %.4f', p_value));
    legend({'Null Distribution', sprintf('Observed (%.1f%%)', results.observed_cv), ...
            sprintf('Null Mean (%.1f%%)', results.null_mean)}, 'Location', 'best');
    grid on;

    % Panel 2: Empirical cumulative distribution function (ECDF)
    subplot(1, 2, 2);
    ecdf(perm_cv_values * 100);
    hold on;
    plot([results.observed_cv, results.observed_cv], [0, 1], 'r-', 'LineWidth', 2);

    xlabel('t50 CV (%)');
    ylabel('Cumulative Probability');
    title('Empirical CDF');
    grid on;

    % ---- Step 7: Report to console ----
    fprintf('\n======= t50 CV Stability Permutation Test =======\n');
    fprintf('Observed t50 CV: %.2f%%\n', results.observed_cv);
    fprintf('Null distribution mean: %.2f%%\n', results.null_mean);
    fprintf('Null distribution 95%% CI: [%.2f%%, %.2f%%]\n', results.null_95ci(1), results.null_95ci(2));
    fprintf('Number of successful permutations: %d\n', length(perm_cv_values));
    fprintf('p‑value: %.4f\n', p_value);

    % Interpret the result
    if p_value < 0.05
        fprintf('Conclusion: The instability of t50 estimate is significantly higher\n');
        fprintf('            than expected by random chance. This may indicate\n');
        fprintf('            model instability or systematic error.\n');
    else
        fprintf('Conclusion: The instability of t50 estimate is within the range\n');
        fprintf('            of random fluctuations. Model stability is acceptable.\n');
    end
end