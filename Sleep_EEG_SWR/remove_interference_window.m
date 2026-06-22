function result = remove_interference_window(signal, threshold, varargin)
% remove_interference_window: Remove signal segments with excessive high-amplitude
%   activity based on a sliding‑window threshold.
%
%   This function scans the signal with overlapping windows, flags windows
%   where the proportion of samples exceeding the absolute threshold is above
%   a given ratio, and sets those samples to zero. Optionally, it can require
%   a minimum number of consecutive flagged windows before applying the mask.
%
%   Inputs:
%       signal        : Input signal (vector).
%       threshold     : Absolute voltage threshold (e.g., 1.5).
%       varargin      : Optional name‑value pairs:
%           'WindowSize'          : Window length in samples (default: 100).
%           'Overlap'             : Overlap fraction (0‑1, default: 0.5).
%           'ThresholdRatio'      : Fraction of samples above threshold needed to flag (0‑1, default: 0.8).
%           'Fs'                  : Sampling rate (Hz); if provided, uses 'WindowTime'.
%           'WindowTime'          : Window duration in seconds (default: 0.1).
%           'MinConsecutiveWindows': Minimum number of consecutive flagged windows (default: 1).
%
%   Output:
%       result        : Signal with flagged regions set to zero.

    % Parse inputs
    p = inputParser;
    addRequired(p, 'signal');
    addRequired(p, 'threshold');
    addParameter(p, 'WindowSize', 100, @isnumeric);
    addParameter(p, 'Overlap', 0.5, @isnumeric);
    addParameter(p, 'ThresholdRatio', 0.8, @isnumeric);
    addParameter(p, 'Fs', [], @isnumeric);
    addParameter(p, 'WindowTime', 0.1, @isnumeric);
    addParameter(p, 'MinConsecutiveWindows', 1, @isnumeric);
    parse(p, signal, threshold, varargin{:});

    % Extract parameters
    signal = signal(:);
    N = length(signal);

    if ~isempty(p.Results.Fs)
        window_size = round(p.Results.WindowTime * p.Results.Fs);
    else
        window_size = p.Results.WindowSize;
    end

    overlap = p.Results.Overlap;
    threshold_ratio = p.Results.ThresholdRatio;
    min_consecutive = p.Results.MinConsecutiveWindows;

    % Ensure sensible window size
    window_size = min(window_size, N);
    window_size = max(window_size, 10);

    step_size = round(window_size * (1 - overlap));
    step_size = max(step_size, 1);

    % Initialize mask
    interference_mask = false(N, 1);
    num_windows = floor((N - window_size) / step_size) + 1;
    window_stats = zeros(num_windows, 1);

    % Slide window
    for i = 1:num_windows
        start_idx = (i-1) * step_size + 1;
        end_idx = start_idx + window_size - 1;
        if end_idx > N
            break;
        end
        window_signal = signal(start_idx:end_idx);
        exceed_ratio = sum(abs(window_signal) > threshold) / window_size;
        window_stats(i) = exceed_ratio;
        if exceed_ratio >= threshold_ratio
            interference_mask(start_idx:end_idx) = true;
        end
    end

    % Optionally refine mask by requiring consecutive flagged windows
    if min_consecutive > 1
        interference_mask = refine_interference_mask(...
            window_stats, threshold_ratio, ...
            window_size, step_size, N, min_consecutive);
    end

    % Apply mask
    result = signal;
    result(interference_mask) = 0;

    % Print statistics
    print_statistics(signal, result, interference_mask, ...
                     window_stats, threshold, threshold_ratio);
end

% ========== Helper functions ==========
function refined_mask = refine_interference_mask(...
        window_stats, threshold_ratio, ...
        window_size, step_size, N, min_consecutive)
    % Refine mask: only keep regions where at least 'min_consecutive'
    % consecutive windows were flagged.

    window_exceeds = window_stats >= threshold_ratio;
    num_windows = length(window_stats);
    diff_exceeds = diff([0; window_exceeds(:); 0]);
    start_windows = find(diff_exceeds == 1);
    end_windows = find(diff_exceeds == -1) - 1;

    refined_mask = false(N, 1);
    for i = 1:length(start_windows)
        start_win = start_windows(i);
        end_win = end_windows(i);
        if (end_win - start_win + 1) >= min_consecutive
            start_idx = (start_win-1) * step_size + 1;
            end_idx = min((end_win-1) * step_size + window_size, N);
            refined_mask(start_idx:end_idx) = true;
        end
    end
end

function print_statistics(signal, processed_signal, mask, ...
        window_stats, threshold, threshold_ratio)
    % Print summary statistics to console.

    N = length(signal);
    interference_samples = sum(mask);
    interference_ratio = interference_samples / N * 100;

    fprintf('\n=== Interference Detection Statistics ===\n');
    fprintf('Signal length: %d samples\n', N);
    fprintf('Threshold: ±%.3f V\n', threshold);
    fprintf('Threshold ratio: %.1f%%\n', threshold_ratio * 100);
    fprintf('Samples removed: %d (%.2f%%)\n', interference_samples, interference_ratio);

    avg_exceed = mean(window_stats) * 100;
    max_exceed = max(window_stats) * 100;
    fprintf('Average exceed ratio per window: %.2f%%\n', avg_exceed);
    fprintf('Maximum exceed ratio per window: %.2f%%\n', max_exceed);

    orig_rms = rms(signal);
    proc_rms = rms(processed_signal);
    reduction = (1 - proc_rms / orig_rms) * 100;
    fprintf('Original RMS: %.4f V\n', orig_rms);
    fprintf('Processed RMS: %.4f V\n', proc_rms);
    fprintf('RMS reduction: %.2f%%\n', reduction);
end