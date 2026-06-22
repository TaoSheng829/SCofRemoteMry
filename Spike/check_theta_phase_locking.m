function [is_locked, p_value, mean_phase, locking_strength] = check_theta_phase_locking(voltage_data, spike_times, analysis_window, fs, options)
% CHECK_THETA_PHASE_LOCKING  Test whether spikes exhibit significant theta‑phase locking.
%
%   This function extracts the instantaneous phase of the theta‑band (4–12 Hz)
%   filtered LFP/voltage signal, computes the phase at each spike time within
%   a specified window, and performs a statistical test (Rayleigh, Rao spacing,
%   or circular) to determine whether the spikes are significantly phase‑locked
%   to the theta rhythm.
%
%   Inputs:
%       voltage_data   - Voltage signal vector (mV), sampled at fs.
%       spike_times    - Spike timestamp vector (seconds).
%       analysis_window- [start_time, end_time] in seconds.
%       fs             - Sampling rate (Hz).
%       options        - Optional structure with fields:
%           .theta_band    - Theta frequency band [low, high] (default: [4, 12] Hz).
%           .alpha         - Significance level (default: 0.05).
%           .min_spikes    - Minimum number of spikes required (default: 10).
%           .filter_order  - Butterworth filter order (default: 4).
%           .method        - Test method: 'rayleigh' (default), 'rao', or 'circular'.
%
%   Outputs:
%       is_locked        - Logical, true if significant phase locking is detected.
%       p_value          - p‑value of the statistical test.
%       mean_phase       - Mean preferred phase (radians, 0–2π).
%       locking_strength - Strength of locking (0–1), equal to the mean vector length.
%
%   Example:
%       window = [100, 200];  % Analyze 100–200 seconds
%       [locked, pval, phase, strength] = check_theta_phase_locking(voltage, spikes, window, 1000);
%
%       % With custom options
%       opts.theta_band = [6, 10];
%       opts.alpha = 0.01;
%       [locked, pval] = check_theta_phase_locking(voltage, spikes, window, 1000, opts);

    % ---- Parameter checking and default values ----
    if nargin < 5
        options = struct();
    end

    default_params = struct(...
        'theta_band', [4, 12], ...
        'alpha', 0.05, ...
        'min_spikes', 10, ...
        'filter_order', 4, ...
        'method', 'rayleigh' ...
    );

    % Merge user options with defaults
    option_fields = fieldnames(default_params);
    for i = 1:length(option_fields)
        field = option_fields{i};
        if ~isfield(options, field)
            options.(field) = default_params.(field);
        end
    end

    % ---- Validate analysis window ----
    if numel(analysis_window) ~= 2 || analysis_window(1) >= analysis_window(2)
        error('analysis_window must be a 2‑element vector with start < end.');
    end

    % ---- Initialise outputs ----
    is_locked = false;
    p_value = NaN;
    mean_phase = NaN;
    locking_strength = 0;

    % ---- Create time vector ----
    total_samples = length(voltage_data);
    total_time = total_samples / fs;
    t = linspace(0, total_time - 1/fs, total_samples);

    % ---- Extract data within the window ----
    win_start = analysis_window(1);
    win_end = analysis_window(2);

    if win_start < 0 || win_end > total_time
        warning('Analysis window exceeds data range.');
        return;
    end

    time_indices = t >= win_start & t < win_end;
    if sum(time_indices) == 0
        warning('No voltage data within the specified time window.');
        return;
    end

    current_voltage = voltage_data(time_indices);
    current_time = t(time_indices);

    % ---- Extract spikes within the window ----
    spike_indices = spike_times >= win_start & spike_times < win_end;
    current_spikes = spike_times(spike_indices);

    % ---- Check minimum spike count ----
    if length(current_spikes) < options.min_spikes
        fprintf('Insufficient spikes: %d (minimum required: %d)\n', ...
                length(current_spikes), options.min_spikes);
        return;
    end

    % ---- 1. Filter to theta band ----
    theta_low = options.theta_band(1);
    theta_high = options.theta_band(2);
    [b, a] = butter(options.filter_order, [theta_low, theta_high]/(fs/2), 'bandpass');
    theta_signal = filtfilt(b, a, current_voltage);

    % ---- 2. Hilbert transform to obtain instantaneous phase ----
    analytic_signal = hilbert(theta_signal);
    instant_phase = angle(analytic_signal);        % [-π, π]
    instant_phase = mod(instant_phase, 2*pi);      % [0, 2π]

    % ---- 3. Extract phase at each spike time ----
    spike_phases = zeros(length(current_spikes), 1);
    for spike_idx = 1:length(current_spikes)
        [~, time_idx] = min(abs(current_time - current_spikes(spike_idx)));
        if time_idx <= length(instant_phase)
            spike_phases(spike_idx) = instant_phase(time_idx);
        end
    end

    % Remove invalid phases (if any)
    valid_phases = spike_phases(spike_phases ~= 0);
    if length(valid_phases) < options.min_spikes
        fprintf('Valid phases insufficient: %d (minimum required: %d)\n', ...
                length(valid_phases), options.min_spikes);
        return;
    end

    % ---- 4. Compute phase locking statistics ----
    phase_vectors = exp(1i * valid_phases);
    mean_vector = mean(phase_vectors);

    % Mean phase (in [0, 2π))
    mean_phase = angle(mean_vector);
    if mean_phase < 0
        mean_phase = mean_phase + 2*pi;
    end

    % Locking strength = magnitude of the mean vector
    locking_strength = abs(mean_vector);

    % ---- 5. Statistical test ----
    n = length(valid_phases);

    switch lower(options.method)
        case 'rayleigh'
            % Rayleigh uniformity test
            p_value = rayleigh_test(valid_phases, n, locking_strength);

        case 'rao'
            % Rao spacing test (good for small samples)
            p_value = rao_spacing_test(valid_phases);

        case 'circular'
            % Circular V‑test (for known direction), here we use Rayleigh as fallback
            p_value = rayleigh_test(valid_phases, n, locking_strength);

        otherwise
            warning('Unknown method; using Rayleigh test.');
            p_value = rayleigh_test(valid_phases, n, locking_strength);
    end

    % ---- 6. Decision ----
    is_locked = p_value < options.alpha;

    % ---- 7. Optionally display summary ----
    if nargout == 0 || options.alpha == 0.05
        fprintf('\n=== Theta Phase‑Locking Results ===\n');
        fprintf('Window: %.1f – %.1f s\n', win_start, win_end);
        fprintf('Theta band: %d – %d Hz\n', theta_low, theta_high);
        fprintf('Spike count: %d\n', n);
        fprintf('Mean preferred phase: %.1f°\n', rad2deg(mean_phase));
        fprintf('Locking strength: %.3f\n', locking_strength);
        fprintf('p‑value: %.4f\n', p_value);

        if is_locked
            fprintf('Conclusion: ✓ Significant theta phase locking (p < %.3f)\n', options.alpha);
        else
            fprintf('Conclusion: ✗ No significant theta phase locking\n');
        end
        fprintf('====================================\n');
    end

end % Main function

%% ========== Helper: Rayleigh uniformity test ==========
function p = rayleigh_test(phases, n, R)
% rayleigh_test: Rayleigh test for circular uniformity.
%   Null hypothesis: phases are uniformly distributed.
%   R = mean resultant length.
%
%   Small‑sample correction is applied for n < 50.

    if n < 50
        % Berens (2009) small‑sample correction
        R_corrected = R * (1 + 1/(2*n));
    else
        R_corrected = R;
    end

    Z = n * R_corrected^2;          % Rayleigh statistic

    % p‑value approximation (large sample: 2Z ~ chi² with 2 df)
    if n > 10
        p = exp(-Z) * (1 + (2*Z - Z^2)/(4*n) - (24*Z - 132*Z^2 + 76*Z^3 - 9*Z^4)/(288*n^2));
    else
        p = exp(-Z) * (1 + (2*Z - Z^2)/(4*n));
    end

    p = max(min(p, 1), 0);           % Ensure within [0,1]
end

%% ========== Helper: Rao spacing test ==========
function p = rao_spacing_test(phases)
% rao_spacing_test: Rao's spacing test for circular uniformity.
%   Particularly suitable for small sample sizes.
%   Uses approximation based on the Rao statistic U.

    sorted_phases = sort(phases);
    n = length(sorted_phases);

    % Compute spacings between successive phases
    spacings = diff(sorted_phases);
    % Add the wrap‑around spacing (last to first + 2π)
    spacings = [spacings; 2*pi - sorted_phases(end) + sorted_phases(1)];

    U = 0.5 * sum(abs(spacings - 2*pi/n));   % Rao statistic

    % Approximate p‑value based on critical values (simplified)
    if n <= 10
        % Small‑sample approximations (from critical tables)
        if U > 212.0/n
            p = 0.001;
        elseif U > 152.5/n
            p = 0.01;
        elseif U > 138.3/n
            p = 0.02;
        elseif U > 129.6/n
            p = 0.05;
        elseif U > 122.6/n
            p = 0.10;
        else
            p = 1.0;
        end
    else
        % Large‑sample chi‑square approximation
        chi2 = 2*(2*pi - U) * n / pi;
        p = 1 - chi2cdf(chi2, 2*n);
    end
end

%% ========== Helper: Additional phase metrics (unused but provided) ==========
function [MI, ppc] = additional_phase_metrics(spike_phases)
% additional_phase_metrics: Compute Modulation Index (MI) and Pairwise Phase
%   Consistency (PPC) as supplementary measures of phase locking.
%
%   MI is based on entropy (higher = more concentrated).
%   PPC is unbiased with respect to sample size (Vinck et al., 2010).

    n = length(spike_phases);
    phase_vectors = exp(1i * spike_phases);

    % 1. Modulation Index (based on Shannon entropy)
    M = 18;                                 % 18 bins of 20° each
    phase_bins = linspace(0, 2*pi, M+1);
    phase_counts = histcounts(spike_phases, phase_bins);
    phase_prob = phase_counts / n;

    entropy = -sum(phase_prob(phase_prob > 0) .* log(phase_prob(phase_prob > 0)));
    max_entropy = log(M);
    MI = (max_entropy - entropy) / max_entropy;

    % 2. Pairwise Phase Consistency (PPC)
    if n > 1
        ppc_matrix = zeros(n, n);
        for i = 1:n
            for j = i+1:n
                ppc_matrix(i, j) = cos(spike_phases(i) - spike_phases(j));
            end
        end
        ppc = 2 * sum(ppc_matrix(:)) / (n * (n-1));
    else
        ppc = 0;
    end
end