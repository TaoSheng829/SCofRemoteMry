%% CCG_jitter.m: Cross-Correlogram Analysis with Jitter Significance Testing
% This script performs a comprehensive cross-correlogram (CCG) analysis
% between two groups of neurons (Group A: HPC, Group B: PFC) with
% statistical significance assessed via a jitter (trial-shuffling) test.
% The analysis identifies directional relationships (A→B, B→A, bidirectional)
% and generates diagnostic figures for each neuron pair. Results are saved
% as vector graphics (EPS by default) and summarized in summary plots.
%
% The script includes multiple significance assessment methods:
%   1) Traditional contiguous-bin method
%   2) Peak-based method (allows single significant bins)
%   3) Combined method (uses whichever gives stronger evidence)
%
% Dependencies: Requires MATLAB's Signal Processing Toolbox for findpeaks
% (if not available, use a custom peak-finding routine).

clear; clc; close all;

%% ===================== 1. Parameter Settings ==============================
% These parameters control the CCG computation, jitter test, and significance criteria.
bin_num = 20;                % Number of bins in the CCG (total, spanning both sides)
window_ms = 200;             % Time window (milliseconds) around each reference spike
jitter_window = 0.05;        % Jitter window size (seconds) for shuffling spike times
n_jitter = 500;              % Number of jitter iterations (recommend 1000, but 500 is faster)
alpha = 0.05;                % Significance level (two-tailed)
min_contiguous_bins = 2;     % Minimum number of contiguous significant bins required
max_peak_width = 5;          % Maximum allowed width of a peak (in bins) to avoid broad peaks

% Significance method selection:
%   1: Traditional method (requires contiguous bins)
%   2: Peak-based method (allows isolated significant bins)
%   3: Combined method (either contiguous or strong isolated peak)
significance_method = 3;

output_format = 'eps';       % Output format: 'eps' (vector), 'pdf', 'svg', 'png'
output_dir = 'CCG_Figures';  % Directory to save figures
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% ===================== 2. Load Spike Data ================================
% Group A: HPC (Hippocampus) neurons (5 neurons)
load('**.mat');
A_spikes = cell(5, 1);
for i = 1:5
    A_spikes{i} = spike.ts{i+11};     % HPC neurons (indices 12-16)
end

% Group B: PFC (Prefrontal Cortex) neurons (8 neurons)
B_spikes = cell(8, 1);
for i = 1:8
    B_spikes{i} = spike.ts{i+3};      % PFC neurons (indices 4-11)
end

% (Optional: artificially add correlated spikes to test the algorithm)
% if isempty(A_spikes{1}) == false && isempty(B_spikes{1}) == false
%     n_correlated = min(30, length(A_spikes{1}));
%     correlated_idx = randperm(length(A_spikes{1}), n_correlated);
%     correlated_spikes = A_spikes{1}(correlated_idx) + 0.010;
%     B_spikes{1} = sort([B_spikes{1}; correlated_spikes]);
% end

%% ===================== 3. Run Main Analysis ==============================
fprintf('Starting CCG analysis...\n');
[ccg_matrix, is_significant, relationship, diagnostic_info] = analyze_CCG_with_jitter(...
    A_spikes, B_spikes, bin_num, window_ms, jitter_window, n_jitter, ...
    alpha, min_contiguous_bins, max_peak_width, significance_method, ...
    output_format, output_dir);

%% ===================== 4. Summarize Results ==============================
summarize_results(is_significant, relationship, A_spikes, B_spikes, diagnostic_info);

fprintf('\nAnalysis complete! All CCG figures saved as %s vector graphics in %s directory.\n', ...
        output_format, output_dir);

%% ===================== 5. Optionally Save Results ========================
save('CCG_analysis_results.mat', 'ccg_matrix', 'is_significant', 'relationship', ...
     'bin_num', 'window_ms', 'jitter_window', 'n_jitter', 'alpha', 'diagnostic_info');

%% ===================== FUNCTION DEFINITIONS ==============================

%% ----- Main Analysis Function --------------------------------------------
function [ccg_matrix, is_significant, relationship, diagnostic_info] = analyze_CCG_with_jitter(...
    A_spikes, B_spikes, bin_num, window_ms, jitter_window, n_jitter, alpha, ...
    min_contiguous_bins, max_peak_width, significance_method, output_format, output_dir)
% analyze_CCG_with_jitter: Compute CCG for all pairs, perform jitter test,
%   assess significance, and save diagnostic figures.
%
% Inputs:
%   A_spikes, B_spikes : Cell arrays of spike time vectors (seconds) for each neuron.
%   bin_num, window_ms : CCG parameters.
%   jitter_window, n_jitter : Jitter test parameters.
%   alpha : Significance level.
%   min_contiguous_bins, max_peak_width : Significance criteria.
%   significance_method : 1, 2, or 3 (see above).
%   output_format, output_dir : Figure saving options.
%
% Outputs:
%   ccg_matrix : Cell array (nA x nB) with observed CCG vectors.
%   is_significant : Matrix (nA x nB) with 0=no, 1=A→B, 2=B→A, 3=bidirectional.
%   relationship : Matrix with peak correlation strength (for significant pairs).
%   diagnostic_info : Cell array with diagnostic structures for each pair.

    nA = length(A_spikes);
    nB = length(B_spikes);

    % Preallocate output arrays
    ccg_matrix = cell(nA, nB);
    is_significant = zeros(nA, nB);
    relationship = zeros(nA, nB);
    diagnostic_info = cell(nA, nB);

    % Time axis for CCG
    window_sec = window_ms / 1000;
    bin_width = 2 * window_sec / bin_num;
    time_axis = linspace(-window_sec, window_sec, bin_num+1);
    time_axis_center = (time_axis(1:end-1) + time_axis(2:end)) / 2;

    % Loop over all neuron pairs
    for i = 1:nA
        for j = 1:nB
            fprintf('\nAnalyzing A%d - B%d ...\n', i, j);

            spikes_A = A_spikes{i};
            spikes_B = B_spikes{j};

            if isempty(spikes_A) || isempty(spikes_B)
                ccg_matrix{i,j} = zeros(1, bin_num);
                diagnostic_info{i,j} = struct('message', 'No spike data');
                continue;
            end

            % Compute observed CCG
            [ccg_obs, ~] = calculate_ccg(spikes_A, spikes_B, window_sec, bin_num);
            ccg_matrix{i,j} = ccg_obs;

            % Perform jitter test to obtain confidence intervals
            [ccg_jitter, threshold_up, threshold_down] = jitter_test(...
                spikes_A, spikes_B, window_sec, bin_num, jitter_window, n_jitter, alpha);

            % Assess significance using the selected method
            [sig_type, sig_strength, diag] = assess_significance_advanced(...
                ccg_obs, threshold_up, threshold_down, time_axis_center, ...
                min_contiguous_bins, max_peak_width, significance_method, i, j);

            is_significant(i, j) = sig_type;
            relationship(i, j) = sig_strength;
            diagnostic_info{i,j} = diag;

            % Display diagnostic info
            fprintf('   Peak positions: ');
            if ~isempty(diag.peak_positions)
                fprintf('%.1fms ', diag.peak_positions*1000);
            else
                fprintf('No significant peaks ');
            end
            fprintf('\n');
            fprintf('   Significance conclusion: %s\n', diag.conclusion);

            % Generate and save CCG figure (without displaying)
            save_ccg_figure(ccg_obs, ccg_jitter, threshold_up, threshold_down, ...
                           time_axis_center, sig_type, sig_strength, diag, ...
                           i, j, window_ms, output_format, output_dir);
        end
    end
end

%% ----- CCG Calculation Function ------------------------------------------
function [ccg, time_axis] = calculate_ccg(spikes_ref, spikes_target, window_sec, bin_num)
% calculate_ccg: Compute cross-correlogram between reference and target spikes.
%   Returns the spike count per bin normalized by the number of reference spikes.
%
% Inputs:
%   spikes_ref    : Vector of reference spike times (seconds).
%   spikes_target : Vector of target spike times (seconds).
%   window_sec    : Half-window size (seconds).
%   bin_num       : Total number of bins (across the full 2*window).
% Outputs:
%   ccg           : 1 x bin_num vector of normalized counts.
%   time_axis     : (Optional) Bin centers (not returned here).

    bin_width = 2 * window_sec / bin_num;
    time_axis = linspace(-window_sec, window_sec, bin_num+1); % not used
    ccg = zeros(1, bin_num);

    % For each reference spike, find target spikes within the window
    for i = 1:length(spikes_ref)
        ref_time = spikes_ref(i);
        target_idx = find(spikes_target >= ref_time - window_sec & ...
                          spikes_target <= ref_time + window_sec);

        if ~isempty(target_idx)
            time_diffs = spikes_target(target_idx) - ref_time;
            for k = 1:length(time_diffs)
                bin_idx = floor((time_diffs(k) + window_sec) / bin_width) + 1;
                bin_idx = max(1, min(bin_num, bin_idx));
                ccg(bin_idx) = ccg(bin_idx) + 1;
            end
        end
    end

    % Normalize by number of reference spikes (probability per reference spike)
    if length(spikes_ref) > 0
        ccg = ccg / length(spikes_ref);
    end
end

%% ----- Jitter Test Function ----------------------------------------------
function [ccg_jitter, threshold_up, threshold_down] = jitter_test(...
    spikes_ref, spikes_target, window_sec, bin_num, jitter_window, n_jitter, alpha)
% jitter_test: Generate a null distribution by randomly jittering reference spikes.
%   Returns the jitter CCGs for each iteration and the upper/lower thresholds
%   for each bin based on the alpha significance level (two-tailed).

    ccg_jitter = zeros(n_jitter, bin_num);

    for iter = 1:n_jitter
        % Jitter the reference spike times by uniform random shift within ±jitter_window
        spikes_ref_jitter = spikes_ref + (rand(size(spikes_ref)) - 0.5) * jitter_window;
        % Compute CCG for jittered spikes
        ccg_jitter(iter, :) = calculate_ccg(spikes_ref_jitter, spikes_target, window_sec, bin_num);
    end

    % Compute percentile-based thresholds for each bin
    threshold_up = zeros(1, bin_num);
    threshold_down = zeros(1, bin_num);
    for b = 1:bin_num
        sorted_vals = sort(ccg_jitter(:, b));
        idx_up = min(round((1 - alpha/2) * n_jitter), n_jitter);
        idx_down = max(round((alpha/2) * n_jitter), 1);
        threshold_up(b) = sorted_vals(idx_up);
        threshold_down(b) = sorted_vals(idx_down);
    end
end

%% ----- Advanced Significance Assessment (with diagnostics) ---------------
function [sig_type, sig_strength, diag] = assess_significance_advanced(...
    ccg_obs, threshold_up, threshold_down, time_axis, min_contiguous_bins, ...
    max_peak_width, method, i, j)
% assess_significance_advanced: Determine direction and strength of connectivity
%   using one of three methods. Returns a diagnostic structure with details.
%
% Inputs:
%   ccg_obs : Observed CCG vector.
%   threshold_up, threshold_down : Confidence interval bounds.
%   time_axis : Bin centers (in seconds).
%   min_contiguous_bins : Required number of consecutive significant bins.
%   max_peak_width : Maximum allowable peak width (bins) for peak-based method.
%   method : 1, 2, or 3.
%   i, j : Indices (for diagnostics only).
% Outputs:
%   sig_type : 0=no, 1=A→B, 2=B→A, 3=bidirectional.
%   sig_strength : Max correlation strength (peak height).
%   diag : Structure with detailed diagnostic fields.

    % Initialize diagnostic structure
    diag = struct();
    diag.ccg_obs = ccg_obs;
    diag.threshold_up = threshold_up;
    diag.threshold_down = threshold_down;
    diag.time_axis = time_axis;
    diag.significant_bins_up = [];
    diag.significant_bins_down = [];
    diag.peak_positions = [];
    diag.peak_heights = [];
    diag.exc_regions = {};
    diag.inh_regions = {};
    diag.conclusion = 'Pending analysis';

    % Identify bins where CCG exceeds or falls below threshold
    sig_up = ccg_obs > threshold_up;      % Excitatory (positive correlation)
    sig_down = ccg_obs < threshold_down;  % Inhibitory (negative correlation)
    diag.significant_bins_up = find(sig_up);
    diag.significant_bins_down = find(sig_down);

    % Find peaks using MATLAB's findpeaks (requires Signal Processing Toolbox)
    % If not available, a simple local maxima detection can be substituted.
    [peaks, peak_locs] = findpeaks(ccg_obs, 'MinPeakHeight', max(threshold_up)*0.5);
    diag.peak_positions = time_axis(peak_locs);
    diag.peak_heights = peaks;

    % Apply the selected significance method
    switch method
        case 1  % Traditional: requires contiguous significant bins
            [sig_type, sig_strength, diag] = method_traditional(...
                ccg_obs, sig_up, sig_down, time_axis, min_contiguous_bins, diag);

        case 2  % Peak-based: allows isolated significant bins
            [sig_type, sig_strength, diag] = method_peak_based(...
                ccg_obs, sig_up, sig_down, time_axis, max_peak_width, diag);

        case 3  % Combined: use whichever yields stronger evidence
            [sig_type1, sig_strength1, diag1] = method_traditional(...
                ccg_obs, sig_up, sig_down, time_axis, min_contiguous_bins, diag);
            [sig_type2, sig_strength2, diag2] = method_peak_based(...
                ccg_obs, sig_up, sig_down, time_axis, max_peak_width, diag);

            if sig_type1 ~= 0 || sig_type2 ~= 0
                if sig_strength1 > sig_strength2
                    sig_type = sig_type1;
                    sig_strength = sig_strength1;
                    diag = diag1;
                    diag.conclusion = 'Combined: traditional method detected significance';
                else
                    sig_type = sig_type2;
                    sig_strength = sig_strength2;
                    diag = diag2;
                    diag.conclusion = 'Combined: peak-based method detected significance';
                end
            else
                sig_type = 0;
                sig_strength = 0;
                diag.conclusion = 'Combined: no significant connectivity detected';
            end
    end

    % Append type and strength to diagnostic
    diag.sig_type = sig_type;
    diag.sig_strength = sig_strength;
end

%% ----- Method 1: Traditional (Contiguous Bins) ---------------------------
function [sig_type, sig_strength, diag] = method_traditional(...
    ccg_obs, sig_up, sig_down, time_axis, min_contiguous_bins, diag)
% method_traditional: Requires at least 'min_contiguous_bins' consecutive
%   bins above threshold to consider a connection. Direction is determined
%   by whether significant clusters fall in positive (A→B) or negative (B→A) lags.

    % Find contiguous regions of significance
    [exc_regions, exc_lengths] = find_contiguous_regions(sig_up, min_contiguous_bins);
    [inh_regions, inh_lengths] = find_contiguous_regions(sig_down, min_contiguous_bins);

    diag.exc_regions = exc_regions;
    diag.inh_regions = inh_regions;

    % Check for positive lag clusters (A drives B)
    a_drives_b = false;
    max_exc_strength = 0;
    max_exc_position = 0;

    for r = 1:length(exc_regions)
        region = exc_regions{r};
        region_times = time_axis(region);
        if any(region_times > 0)
            [region_max, max_idx] = max(ccg_obs(region));
            if region_max > max_exc_strength
                max_exc_strength = region_max;
                max_exc_position = region_times(max_idx);
            end
            a_drives_b = true;
        end
    end

    % Check for negative lag clusters (B drives A)
    b_drives_a = false;
    for r = 1:length(exc_regions)
        region = exc_regions{r};
        region_times = time_axis(region);
        if any(region_times < 0)
            b_drives_a = true;
        end
    end

    % Determine connection type
    if a_drives_b && b_drives_a
        sig_type = 3;  % bidirectional
        diag.conclusion = sprintf('Traditional: bidirectional (strength: %.3f @ %.1fms)', ...
                                  max_exc_strength, max_exc_position*1000);
    elseif a_drives_b
        sig_type = 1;  % A→B
        diag.conclusion = sprintf('Traditional: A→B (strength: %.3f @ %.1fms)', ...
                                  max_exc_strength, max_exc_position*1000);
    elseif b_drives_a
        sig_type = 2;  % B→A
        diag.conclusion = sprintf('Traditional: B→A (strength: %.3f @ %.1fms)', ...
                                  max_exc_strength, max_exc_position*1000);
    else
        sig_type = 0;
        if ~isempty(exc_regions) && isempty(exc_regions{1})
            diag.conclusion = 'Traditional: significant bins exist but not contiguous';
        else
            diag.conclusion = 'Traditional: no significant bins';
        end
    end

    sig_strength = max_exc_strength;
end

%% ----- Method 2: Peak-Based (Isolated Bins Allowed) ----------------------
function [sig_type, sig_strength, diag] = method_peak_based(...
    ccg_obs, sig_up, sig_down, time_axis, max_peak_width, diag)
% method_peak_based: Any single bin above threshold is considered significant.
%   Direction determined by the sign of the lag (positive/negative).

    sig_up_bins = find(sig_up);
    sig_down_bins = find(sig_down);

    % Check positive lags (A→B)
    a_drives_b = false;
    max_exc_strength = 0;
    max_exc_position = 0;
    for b = sig_up_bins
        if time_axis(b) > 0
            if ccg_obs(b) > max_exc_strength
                max_exc_strength = ccg_obs(b);
                max_exc_position = time_axis(b);
            end
            a_drives_b = true;
        end
    end

    % Check negative lags (B→A)
    b_drives_a = false;
    for b = sig_up_bins
        if time_axis(b) < 0
            b_drives_a = true;
        end
    end

    % Determine type
    if a_drives_b && b_drives_a
        sig_type = 3;
        diag.conclusion = sprintf('Peak-based: bidirectional (strength: %.3f @ %.1fms)', ...
                                  max_exc_strength, max_exc_position*1000);
    elseif a_drives_b
        sig_type = 1;
        diag.conclusion = sprintf('Peak-based: A→B (strength: %.3f @ %.1fms)', ...
                                  max_exc_strength, max_exc_position*1000);
    elseif b_drives_a
        sig_type = 2;
        diag.conclusion = sprintf('Peak-based: B→A (strength: %.3f @ %.1fms)', ...
                                  max_exc_strength, max_exc_position*1000);
    else
        sig_type = 0;
        if ~isempty(sig_up_bins)
            diag.conclusion = 'Peak-based: significant bins exist but not in correct direction';
        else
            diag.conclusion = 'Peak-based: no bins exceed threshold';
        end
    end

    sig_strength = max_exc_strength;
end

%% ----- Helper: Find Contiguous Regions -----------------------------------
function [regions, lengths] = find_contiguous_regions(binary_vec, min_length)
% find_contiguous_regions: Identify runs of 1s in a binary vector that are
%   at least 'min_length' long. Returns cell array of indices and lengths.

    regions = {};
    lengths = [];

    if isempty(binary_vec) || all(binary_vec == 0)
        return;
    end

    padded = [0, binary_vec, 0];
    diff_padded = diff(padded);
    starts = find(diff_padded == 1);
    ends = find(diff_padded == -1) - 1;

    for i = 1:length(starts)
        region_len = ends(i) - starts(i) + 1;
        if region_len >= min_length
            regions{end+1} = starts(i):ends(i);
            lengths(end+1) = region_len;
        end
    end
end

%% ----- Save CCG Figure (Vector Format, No Display) -----------------------
function save_ccg_figure(ccg_obs, ccg_jitter, threshold_up, threshold_down, ...
                         time_axis, sig_type, sig_strength, diag, i, j, window_ms, ...
                         output_format, output_dir)
% save_ccg_figure: Create a multi-panel figure with the CCG, jitter distribution,
%   and diagnostic information, then save as vector graphics without showing.

    % Create invisible figure
    fig = figure('Visible', 'off', 'Position', [100, 100, 900, 700], ...
                 'PaperUnits', 'inches', 'PaperSize', [9, 7], ...
                 'PaperPosition', [0, 0, 9, 7], 'Renderer', 'painters');

    % Panel 1: Main CCG with thresholds and markers
    subplot(3, 1, 1);
    bar(time_axis * 1000, ccg_obs, 'FaceColor', [0.2, 0.4, 0.8], 'EdgeColor', 'none');
    hold on;
    plot(time_axis * 1000, threshold_up, 'r-', 'LineWidth', 2, 'DisplayName', 'Significance threshold');
    plot(time_axis * 1000, threshold_down, 'r-', 'LineWidth', 2);
    % Mark significant bins
    if ~isempty(diag.significant_bins_up)
        sig_times = time_axis(diag.significant_bins_up) * 1000;
        sig_values = ccg_obs(diag.significant_bins_up);
        scatter(sig_times, sig_values, 100, 'r', 'filled', 'DisplayName', 'Significant bins');
    end
    % Mark peaks
    if ~isempty(diag.peak_positions)
        scatter(diag.peak_positions * 1000, diag.peak_heights, 80, 'g', '^', 'filled', 'DisplayName', 'Peaks');
    end
    plot([0, 0], ylim, 'k--', 'LineWidth', 1);
    xlabel('Time lag (ms)');
    ylabel('Correlation');
    title(sprintf('A%d - B%d CCG (window: ±%d ms)', i, j, window_ms));
    legend('Location', 'best');
    grid on;
    set(gca, 'FontSize', 10, 'LineWidth', 1);

    % Panel 2: Jitter distribution vs observed CCG
    subplot(3, 1, 2);
    jitter_mean = mean(ccg_jitter, 1);
    jitter_std = std(ccg_jitter, 0, 1);
    plot(time_axis * 1000, jitter_mean, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Jitter mean');
    hold on;
    plot(time_axis * 1000, jitter_mean + jitter_std, 'r--', 'LineWidth', 1, 'DisplayName', 'Mean ± std');
    plot(time_axis * 1000, jitter_mean - jitter_std, 'r--', 'LineWidth', 1);
    plot(time_axis * 1000, ccg_obs, 'b-', 'LineWidth', 2, 'DisplayName', 'Observed CCG');
    plot([0, 0], ylim, 'k--', 'LineWidth', 1);
    xlabel('Time lag (ms)');
    ylabel('Correlation');
    title('Jitter distribution vs observed CCG');
    legend('Location', 'best');
    grid on;
    set(gca, 'FontSize', 10, 'LineWidth', 1);

    % Panel 3: Diagnostic text
    subplot(3, 1, 3);
    axis off;
    info_text = {
        sprintf('=== Diagnostics (A%d-B%d) ===', i, j);
        sprintf('Excitatory bins: %s', mat2str(diag.significant_bins_up));
        sprintf('Inhibitory bins: %s', mat2str(diag.significant_bins_down));
        sprintf('Peak positions: %s ms', sprintf('%.1f ', diag.peak_positions*1000));
        sprintf('Conclusion: %s', diag.conclusion);
        '';
        sprintf('CCG statistics:');
        sprintf('  Max: %.4f @ %.1f ms', max(ccg_obs), time_axis(ccg_obs==max(ccg_obs))*1000);
        sprintf('  Mean: %.4f', mean(ccg_obs));
        sprintf('  Std: %.4f', std(ccg_obs));
        '';
        sprintf('Threshold statistics:');
        sprintf('  Upper threshold mean: %.4f', mean(threshold_up));
        sprintf('  Lower threshold mean: %.4f', mean(threshold_down));
        '';
        sprintf('Significance type: %d (0:none, 1:A→B, 2:B→A, 3:bidirectional)', sig_type);
        sprintf('Connection strength: %.4f', sig_strength);
    };
    text(0.05, 0.95, info_text, 'Units', 'normalized', ...
         'FontSize', 9, 'FontName', 'FixedWidth', ...
         'VerticalAlignment', 'top');

    set(gcf, 'Color', 'white');

    % Save figure
    filename = sprintf('CCG_A%d_B%d', i, j);
    filepath = fullfile(output_dir, filename);

    switch lower(output_format)
        case 'eps'
            print(fig, filepath, '-depsc', '-r300', '-painters');
            fprintf('   Figure saved as: %s.eps\n', filename);
        case 'pdf'
            print(fig, filepath, '-dpdf', '-r300', '-painters');
            fprintf('   Figure saved as: %s.pdf\n', filename);
        case 'svg'
            saveas(fig, filepath, 'svg');
            fprintf('   Figure saved as: %s.svg\n', filename);
        case 'png'
            saveas(fig, filepath, 'png');
            fprintf('   Figure saved as: %s.png\n', filename);
        otherwise
            print(fig, filepath, '-depsc', '-r300', '-painters');
            fprintf('   Figure saved as: %s.eps\n', filename);
    end

    close(fig);
end

%% ----- Summary and Statistics Reporting ----------------------------------
function summarize_results(is_significant, relationship, A_spikes, B_spikes, diagnostic_info)
% summarize_results: Display statistical summary and generate two summary figures:
%   1) Relationship matrix (heatmap with labels)
%   2) Bar chart of connection counts.

    nA = size(is_significant, 1);
    nB = size(is_significant, 2);
    total_pairs = nA * nB;

    no_sig = sum(is_significant(:) == 0);
    a_to_b = sum(is_significant(:) == 1);
    b_to_a = sum(is_significant(:) == 2);
    bidirectional = sum(is_significant(:) == 3);

    % Percentages
    prop_no_sig = no_sig / total_pairs * 100;
    prop_a_to_b = a_to_b / total_pairs * 100;
    prop_b_to_a = b_to_a / total_pairs * 100;
    prop_bidirectional = bidirectional / total_pairs * 100;
    prop_any_sig = (total_pairs - no_sig) / total_pairs * 100;

    % Print to command window
    fprintf('\n========== Statistical Summary ==========\n');
    fprintf('Group A neurons: %d\n', nA);
    fprintf('Group B neurons: %d\n', nB);
    fprintf('Total pairs: %d\n', total_pairs);
    fprintf('\n------ Connectivity counts ------\n');
    fprintf('No significant: %d (%.1f%%)\n', no_sig, prop_no_sig);
    fprintf('A drives B: %d (%.1f%%)\n', a_to_b, prop_a_to_b);
    fprintf('B drives A: %d (%.1f%%)\n', b_to_a, prop_b_to_a);
    fprintf('Bidirectional: %d (%.1f%%)\n', bidirectional, prop_bidirectional);
    fprintf('Any significant: %d (%.1f%%)\n', total_pairs-no_sig, prop_any_sig);

    % Strongest connection
    if any(relationship(:) > 0)
        [max_strength, max_idx] = max(relationship(:));
        [i_max, j_max] = ind2sub(size(relationship), max_idx);
        fprintf('\n------ Strongest connection ------\n');
        fprintf('A%d → B%d, strength: %.4f\n', i_max, j_max, max_strength);
        if ~isempty(diagnostic_info{i_max, j_max})
            diag = diagnostic_info{i_max, j_max};
            fprintf('Diagnostic: %s\n', diag.conclusion);
        end
    end

    % Figure 1: Relationship matrix
    fig_matrix = figure('Visible', 'off', 'Position', [100, 100, 800, 600], ...
                       'PaperUnits', 'inches', 'PaperSize', [8, 6], ...
                       'PaperPosition', [0, 0, 8, 6], 'Renderer', 'painters');

    rel_matrix = is_significant;  % 0,1,2,3
    imagesc(rel_matrix);
    colorbar;
    custom_cmap = [0.9 0.9 0.9; 0.9 0.2 0.2; 0.2 0.2 0.9; 0.9 0.6 0.1];
    colormap(custom_cmap);
    caxis([-0.5, 3.5]);
    xlabel('B neurons');
    ylabel('A neurons');
    title('Connectivity matrix');

    % Annotate with text labels
    for i = 1:nA
        for j = 1:nB
            switch rel_matrix(i, j)
                case 0, label_text = 'none';
                case 1, label_text = 'A→B';
                case 2, label_text = 'B→A';
                case 3, label_text = 'bidir';
            end
            text(j, i, label_text, 'HorizontalAlignment', 'center', ...
                 'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'FontSize', 10);
        end
    end
    set(gca, 'XTick', 1:nB, 'YTick', 1:nA);
    set(gca, 'FontSize', 10, 'LineWidth', 1);
    set(gcf, 'Color', 'white');
    print(fig_matrix, 'Connectivity_Matrix', '-depsc', '-r300', '-painters');
    fprintf('\nConnectivity matrix saved as: Connectivity_Matrix.eps\n');
    close(fig_matrix);

    % Figure 2: Bar chart summary
    fig_summary = figure('Visible', 'off', 'Position', [100, 100, 800, 500], ...
                        'PaperUnits', 'inches', 'PaperSize', [8, 5], ...
                        'PaperPosition', [0, 0, 8, 5], 'Renderer', 'painters');

    categories = {'No sig.', 'A→B', 'B→A', 'Bidir.', 'Any sig.'};
    values = [no_sig, a_to_b, b_to_a, bidirectional, total_pairs-no_sig];
    percentages = [prop_no_sig, prop_a_to_b, prop_b_to_a, prop_bidirectional, prop_any_sig];

    bar(values, 'FaceColor', [0.2, 0.4, 0.8], 'EdgeColor', 'none');
    for i = 1:length(values)
        text(i, values(i)+max(values)*0.02, ...
             sprintf('%d (%.1f%%)', values(i), percentages(i)), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
    end
    set(gca, 'XTickLabel', categories);
    ylabel('Number of pairs');
    title(sprintf('Connectivity summary (total pairs: %d)', total_pairs));
    grid on;
    set(gca, 'FontSize', 10, 'LineWidth', 1);
    set(gcf, 'Color', 'white');
    print(fig_summary, 'Connectivity_Summary', '-depsc', '-r300', '-painters');
    fprintf('Summary bar chart saved as: Connectivity_Summary.eps\n');
    close(fig_summary);
end