function [firing_rate, spike_count, duration] = calculate_firing_rate(spike_times, analysis_window, options)
% CALCULATE_FIRING_RATE  Compute neuronal firing rate within specified time windows.
%
%   Input arguments:
%       spike_times     - Spike timestamp sequence (seconds). Can be a vector or matrix.
%       analysis_window - Analysis time window, supports multiple formats:
%                         1) [start_time, end_time] (seconds) – single window
%                         2) A vector of time points – the function computes the rate
%                            over the full time range (with optional smoothing)
%                         3) A matrix with multiple windows, each row is one window [start, end]
%       options         - Optional parameter structure with fields:
%           .unit        - Firing rate unit: 'Hz' (default), 'spikes/s', 'spikes/min', 'spikes/sec'
%           .smoothing   - Use sliding‑window smoothing: false (default) or true
%           .window_size - Smoothing window size (seconds), default 1
%           .step_size   - Smoothing step size (seconds), default 0.1
%           .min_time    - Minimum time limit; if not provided, uses data minimum
%           .max_time    - Maximum time limit; if not provided, uses data maximum
%
%   Output arguments:
%       firing_rate - Firing rate, format depends on analysis_window:
%                     Single window: scalar
%                     Multiple windows: vector, one element per window
%                     Time points: vector, one element per time point (instantaneous rate)
%       spike_count - Number of spikes within the corresponding window(s)
%       duration    - Duration(s) of the corresponding window(s) in seconds
%
%   Examples:
%       % Basic usage
%       spike_times = sort(rand(100,1)*600);   % 100 spikes in 600 seconds
%       window = [100, 200];
%       rate = calculate_firing_rate(spike_times, window);
%
%       % Multiple windows
%       windows = [40, 100; 140, 200; 240, 300];
%       [rates, counts, durations] = calculate_firing_rate(spike_times, windows);
%
%       % Time‑series analysis with smoothing
%       time_points = 0:10:590;
%       [rates, ~] = calculate_firing_rate(spike_times, time_points, struct('smoothing', true));

% ---- Parameter checking and default values ----
if nargin < 3
    options = struct();
end

% Define default parameters
default_params = struct(...
    'unit', 'Hz', ...          % Default unit is Hz
    'smoothing', false, ...    % No smoothing by default
    'window_size', 1, ...      % Smoothing window size (seconds)
    'step_size', 0.1, ...      % Smoothing step size (seconds)
    'min_time', [], ...        % Minimum time
    'max_time', [] ...         % Maximum time
);

% Merge user options with defaults
option_fields = fieldnames(default_params);
for i = 1:length(option_fields)
    field = option_fields{i};
    if ~isfield(options, field)
        options.(field) = default_params.(field);
    end
end

% ---- Input validation ----
if isempty(spike_times)
    warning('Spike time sequence is empty');
    firing_rate = 0;
    spike_count = 0;
    duration = 0;
    return;
end

% Ensure spike_times is a column vector
if size(spike_times, 2) > 1 && size(spike_times, 1) == 1
    spike_times = spike_times';
end

% Determine time range
if isempty(options.min_time)
    min_time = min(spike_times(:));
else
    min_time = options.min_time;
end

if isempty(options.max_time)
    max_time = max(spike_times(:));
else
    max_time = options.max_time;
end

% ---- Handle different formats of analysis_window ----
if isempty(analysis_window)
    error('analysis_window cannot be empty');
end

% Case 1: Single window [start, end]
if numel(analysis_window) == 2 && size(analysis_window, 1) == 1
    window_start = analysis_window(1);
    window_end = analysis_window(2);

    if window_start >= window_end
        error('Window start time must be less than end time');
    end

    spike_count = sum(spike_times >= window_start & spike_times < window_end);
    duration = window_end - window_start;
    firing_rate = spike_count / duration;
    firing_rate = convert_firing_rate_unit(firing_rate, options.unit);

% Case 2: Multiple windows (n×2 matrix)
elseif size(analysis_window, 2) == 2
    num_windows = size(analysis_window, 1);
    firing_rate = zeros(num_windows, 1);
    spike_count = zeros(num_windows, 1);
    duration = zeros(num_windows, 1);

    for i = 1:num_windows
        window_start = analysis_window(i, 1);
        window_end = analysis_window(i, 2);

        if window_start >= window_end
            warning('Window %d invalid: start >= end, skipping', i);
            firing_rate(i) = NaN;
            spike_count(i) = NaN;
            duration(i) = window_end - window_start;
            continue;
        end

        spike_count(i) = sum(spike_times >= window_start & spike_times < window_end);
        duration(i) = window_end - window_start;
        if duration(i) > 0
            firing_rate(i) = spike_count(i) / duration(i);
        else
            firing_rate(i) = 0;
        end
    end

    firing_rate = convert_firing_rate_unit(firing_rate, options.unit);

% Case 3: Time point vector
elseif isvector(analysis_window)
    time_points = analysis_window(:);

    if options.smoothing
        % Compute instantaneous firing rate using a sliding window
        window_size = options.window_size;
        step_size = options.step_size;

        % Create sliding window centre points
        if isempty(options.min_time) || isempty(options.max_time)
            min_time_smooth = min(spike_times);
            max_time_smooth = max(spike_times);
        else
            min_time_smooth = options.min_time;
            max_time_smooth = options.max_time;
        end

        window_centers = min_time_smooth:step_size:max_time_smooth;
        firing_rate = zeros(length(window_centers), 1);
        spike_count = zeros(length(window_centers), 1);

        for i = 1:length(window_centers)
            center = window_centers(i);
            win_start = center - window_size/2;
            win_end = center + window_size/2;
            spike_count(i) = sum(spike_times >= win_start & spike_times < win_end);
            firing_rate(i) = spike_count(i) / window_size;
        end

        duration = window_size * ones(size(firing_rate));
        firing_rate = convert_firing_rate_unit(firing_rate, options.unit);

        % If output requested, interpolate rates to the given time points
        if nargout > 0
            if length(window_centers) > 1
                firing_rate_interp = interp1(window_centers, firing_rate, time_points, 'linear', 0);
                spike_count_interp = interp1(window_centers, spike_count, time_points, 'nearest', 0);
                firing_rate = firing_rate_interp;
                spike_count = spike_count_interp;
            else
                firing_rate = zeros(size(time_points));
                spike_count = zeros(size(time_points));
            end
            duration = window_size * ones(size(time_points));
        end
    else
        % Non‑smoothing mode: compute rate for a fixed window after each time point
        fixed_window = 1;   % seconds
        firing_rate = zeros(length(time_points), 1);
        spike_count = zeros(length(time_points), 1);

        for i = 1:length(time_points)
            t_point = time_points(i);
            win_start = t_point;
            win_end = t_point + fixed_window;
            spike_count(i) = sum(spike_times >= win_start & spike_times < win_end);
            firing_rate(i) = spike_count(i) / fixed_window;
        end

        duration = fixed_window * ones(size(firing_rate));
        firing_rate = convert_firing_rate_unit(firing_rate, options.unit);
    end
else
    error('analysis_window format not supported. Use: 1) [start,end] vector, 2) n×2 matrix, 3) time point vector');
end

end % Main function end

%% ========== Helper function: Unit conversion ==========
function rate = convert_firing_rate_unit(rate, unit)
% convert_firing_rate_unit: Convert firing rate to the specified unit.
%
%   Input:
%       rate   - Rate in spikes/second (Hz) (scalar or vector)
%       unit   - Target unit string.
%   Output:
%       rate   - Rate expressed in the target unit.

switch lower(unit)
    case {'hz', 'spikes/s', 'spikes/sec'}
        % Already per second – no change
        rate = rate;

    case {'spikes/min', 'spikes/minute'}
        % Convert to per minute
        rate = rate * 60;

    case {'spikes/ms', 'spikes/millisecond'}
        % Convert to per millisecond
        rate = rate / 1000;

    case {'spikes/hour'}
        % Convert to per hour
        rate = rate * 3600;

    otherwise
        warning('Unknown unit: %s, using default Hz', unit);
        % Keep as is
end

end

%% ========== Helper function: Confidence interval (Poisson) ==========
function [rate_ci_low, rate_ci_high] = firing_rate_ci(spike_count, duration, alpha)
% firing_rate_ci: Compute confidence intervals for firing rate based on Poisson distribution.
%
%   Inputs:
%       spike_count - Number of spikes observed.
%       duration    - Observation duration (seconds).
%       alpha       - Significance level (default: 0.05 for 95% CI).
%   Outputs:
%       rate_ci_low  - Lower bound of the confidence interval.
%       rate_ci_high - Upper bound of the confidence interval.
%
%   The function uses the exact Poisson confidence intervals (Garwood, 1936)
%   based on the chi‑square distribution.

if nargin < 3
    alpha = 0.05;
end

% Use chi‑square based exact Poisson confidence intervals
% lambda_low = 0.5 * chi2inv(alpha/2, 2*spike_count)
% lambda_high = 0.5 * chi2inv(1 - alpha/2, 2*(spike_count+1))
lambda_low = 0.5 * chi2inv(alpha/2, 2*spike_count);
lambda_high = 0.5 * chi2inv(1 - alpha/2, 2*(spike_count + 1));

% Convert to firing rate (spikes per second)
rate_ci_low = lambda_low / duration;
rate_ci_high = lambda_high / duration;

end