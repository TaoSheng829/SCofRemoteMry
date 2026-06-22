function result = calculate_phase_preference(voltage_data, spike_times, time_windows, fs)
% CALCULATE_PHASE_PREFERENCE  Compute the mean phase preference of spikes
%   within specified time windows, and return circular‑linear statistics.
%
%   This function extracts the instantaneous phase of a band‑pass filtered
%   (4‑12 Hz, theta) LFP/voltage signal, identifies the phase at each spike
%   time within each window, computes the circular mean phase, and then
%   performs a circular‑linear correlation and linear regression across
%   windows to assess phase precession.
%
%   Input arguments:
%       voltage_data - Voltage signal vector (mV), sampled at rate fs.
%       spike_times  - Spike timestamp vector (seconds).
%       time_windows - n×2 matrix, each row [start, end] in seconds.
%       fs           - Sampling rate (Hz), default 1000.
%
%   Output:
%       result       - Structure with fields:
%           .r2     - Squared circular‑linear correlation coefficient.
%           .p      - p‑value for the correlation.
%           .slope  - Linear regression slope of mean phase vs. window index.
%
%   Example:
%       time_windows = [40, 100; 140, 200; 240, 300; 340, 400; 440, 500];
%       result = calculate_phase_preference(voltage_data, spike_times, time_windows, 1000);

    % ---- Parameter checking and default values ----
    if nargin < 4
        fs = 1000;   % Default sampling rate
    end

    % Validate input
    if size(time_windows, 2) ~= 2
        error('time_windows must be an n×2 matrix, each row containing start and end times.');
    end

    % ---- Create time vector ----
    total_samples = length(voltage_data);
    total_time = total_samples / fs;
    t = linspace(0, total_time - 1/fs, total_samples);

    % ---- Initialize output ----
    num_windows = size(time_windows, 1);
    mean_phases = zeros(num_windows, 1);

    % ---- Loop over each time window ----
    for win_idx = 1:num_windows
        win_start = time_windows(win_idx, 1);
        win_end = time_windows(win_idx, 2);

        % Check window validity
        if win_start < 0 || win_end > total_time || win_start >= win_end
            warning('Window %d (%d‑%d s) out of range or invalid, returning NaN', win_idx, win_start, win_end);
            mean_phases(win_idx) = NaN;
            continue;
        end

        % Extract voltage segment for this window
        time_indices = t >= win_start & t < win_end;
        if sum(time_indices) == 0
            mean_phases(win_idx) = NaN;
            continue;
        end
        current_voltage = voltage_data(time_indices);
        current_time = t(time_indices);

        % Extract spikes within this window
        spike_indices = spike_times >= win_start & spike_times < win_end;
        current_spikes = spike_times(spike_indices);

        % Skip if no spikes in this window
        if isempty(current_spikes)
            mean_phases(win_idx) = NaN;
            continue;
        end

        % ---- Filter voltage signal to theta band (4‑12 Hz) ----
        theta_band = [4, 12];
        [b, a] = butter(4, theta_band/(fs/2), 'bandpass');
        theta_signal = filtfilt(b, a, current_voltage);

        % ---- Hilbert transform to get instantaneous phase ----
        analytic_signal = hilbert(theta_signal);
        instant_phase = angle(analytic_signal);        % [-π, π]
        instant_phase = mod(instant_phase, 2*pi);      % [0, 2π]

        % ---- Extract phase at each spike time ----
        spike_phases = zeros(length(current_spikes), 1);
        for spike_idx = 1:length(current_spikes)
            % Find the closest sample to the spike time
            [~, time_idx] = min(abs(current_time - current_spikes(spike_idx)));
            if time_idx <= length(instant_phase)
                spike_phases(spike_idx) = instant_phase(time_idx);
            end
        end

        % Remove any zero phases (if a spike fell outside the time range)
        valid_phases = spike_phases(spike_phases ~= 0);
        if isempty(valid_phases)
            mean_phases(win_idx) = NaN;
            continue;
        end

        % ---- Compute circular mean phase ----
        phase_vectors = exp(1i * valid_phases);
        mean_vector = mean(phase_vectors);
        mean_phase = angle(mean_vector);

        % Adjust to [0, 2π) range
        if mean_phase < 0
            mean_phase = mean_phase + 2*pi;
        end

        mean_phases(win_idx) = mean_phase;
    end

    % ---- Compute circular‑linear correlation and linear regression ----
    % The X values represent window indices (1 to number_of_windows)
    X = (1:num_windows)';
    [rval, pval] = circ_corrcl(mean_phases, X);   % circular‑linear correlation
    r2val = rval * rval;                           % squared correlation

    % Linear regression: phase ~ window_index
    X_design = [ones(size(X,1), 1), X];            % intercept + slope
    [b, ~, ~, ~, stats] = regress(mean_phases, X_design);

    % ---- Assemble output structure ----
    result.r2 = r2val;
    result.p = pval;
    result.slope = b(2);   % slope coefficient

    % Optionally, convert phases to degrees (commented out)
    % mean_phases = rad2deg(mean_phases);

end