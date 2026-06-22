function [mean_half_width, mean_firing_rate] = calculateMeanSpikeParams(wave, ts, varargin)
% calculateMeanSpikeParams: Compute mean spike waveform parameters.
%
%   This function takes a set of spike waveforms and their timestamps,
%   computes the average waveform, estimates the half‑width (duration from
%   the minimum to the subsequent maximum in the average waveform), and
%   calculates the average firing rate. Optionally, it generates a figure
%   showing the average waveform and summary statistics.
%
%   Inputs:
%       wave      - n×32 matrix of spike waveforms (in mV). Each row is one waveform.
%       ts        - n×1 vector of spike timestamps (in seconds).
%       varargin  - Optional parameter‑value pairs:
%           'visualize' - Logical, whether to plot results (default: false).
%           'fs'        - Sampling rate in Hz (default: 40000).
%
%   Outputs:
%       mean_half_width   - Mean half‑width in microseconds (μs).
%       mean_firing_rate  - Mean firing rate in Hz.

    % ---- Set default parameters ----
    defaultVisualize = false;
    defaultFs = 40000;          % Typical sampling rate for extracellular spikes

    % ---- Parse input arguments ----
    p = inputParser;
    addRequired(p, 'wave', @isnumeric);
    addRequired(p, 'ts', @isnumeric);
    addParameter(p, 'visualize', defaultVisualize, @islogical);
    addParameter(p, 'fs', defaultFs, @isnumeric);
    parse(p, wave, ts, varargin{:});

    visualize = p.Results.visualize;
    fs = p.Results.fs;
    dt = 1/fs;                  % Sampling interval in seconds

    % ---- Input validation ----
    if size(wave, 2) ~= 32
        warning('Waveform points are not 32; actual: %d', size(wave, 2));
    end

    if length(ts) ~= size(wave, 1)
        error('Number of timestamps (%d) does not match number of waveforms (%d).', length(ts), size(wave, 1));
    end

    % ---- 1. Compute the average waveform ----
    mean_wave = mean(wave, 1, 'omitnan');

    % Time axis in milliseconds
    t_ms = (0:31) * dt * 1000;

    % ---- 2. Compute half‑width from the average waveform ----
    % Half‑width is defined as the time from the negative peak (minimum)
    % to the subsequent positive peak (maximum) in the average waveform.
    time_conversion = 1e6;   % seconds → microseconds

    % Find the index of the minimum (negative peak)
    [~, min_idx] = min(mean_wave);

    % Find the index of the maximum after the minimum
    if min_idx < 32
        segment_after_min = mean_wave(min_idx:end);
        [~, max_rel_idx] = max(segment_after_min);
        max_idx = min_idx + max_rel_idx - 1;

        % Verify that the maximum occurs after the minimum and is larger
        if max_idx > min_idx && mean_wave(max_idx) > mean_wave(min_idx)
            half_width_s = (max_idx - min_idx) * dt;
            mean_half_width = half_width_s * time_conversion;   % in μs
        else
            mean_half_width = NaN;
            warning('No valid maximum found after the minimum in the average waveform.');
        end
    else
        mean_half_width = NaN;
        warning('Minimum point is at the end of the waveform; cannot compute half‑width.');
    end

    % ---- 3. Compute mean firing rate (Hz) ----
    if length(ts) > 1
        total_time = ts(end) - ts(1);
        if total_time > 0
            mean_firing_rate = length(ts) / total_time;   % spikes per second
        else
            mean_firing_rate = 0;
            warning('Total time is zero; cannot compute firing rate.');
        end
    else
        mean_firing_rate = 0;
        warning('Insufficient timestamps to compute firing rate.');
    end

    % ---- 4. Display results to command window ----
    fprintf('===== Mean Spike Parameter Results =====\n');
    if isnan(mean_half_width)
        fprintf('Mean half‑width: Cannot compute\n');
    else
        fprintf('Mean half‑width: %.0f μs\n', mean_half_width);
    end
    fprintf('Mean firing rate: %.2f Hz\n', mean_firing_rate);
    fprintf('Number of waveforms: %d\n', size(wave, 1));
    fprintf('Number of timestamps: %d\n', length(ts));
    fprintf('=======================================\n');

    % ---- 5. Optional visualisation ----
    if visualize
        figure('Position', [100, 100, 800, 400]);

        % Subplot 1: Average waveform with markers
        subplot(1, 2, 1);
        plot(t_ms, mean_wave, 'b-', 'LineWidth', 2);
        hold on;

        if ~isnan(mean_half_width)
            % Mark the minimum and maximum points
            plot(t_ms(min_idx), mean_wave(min_idx), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
            plot(t_ms(max_idx), mean_wave(max_idx), 'go', 'MarkerSize', 10, 'LineWidth', 2);

            % Draw a dashed line for the half‑width span
            plot([t_ms(min_idx), t_ms(max_idx)], [mean_wave(min_idx), mean_wave(max_idx)], 'k--', 'LineWidth', 1);

            legend('Average waveform', 'Minimum point', 'Maximum point', 'Half‑width');

            % Annotate the half‑width value
            text_x = (t_ms(min_idx) + t_ms(max_idx)) / 2;
            text_y = (mean_wave(min_idx) + mean_wave(max_idx)) / 2;
            text(text_x, text_y, sprintf('%.0f μs', mean_half_width), ...
                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
                'FontSize', 10, 'FontWeight', 'bold');
        else
            legend('Average waveform');
        end

        xlabel('Time (ms)');
        ylabel('Amplitude (mV)');
        title('Average Waveform');
        grid on;

        % Subplot 2: Summary information panel
        subplot(1, 2, 2);
        axis off;

        if isnan(mean_half_width)
            half_width_str = 'Cannot compute';
        else
            half_width_str = sprintf('%.0f μs', mean_half_width);
        end

        info_text = {
            sprintf('Number of waveforms: %d', size(wave, 1));
            sprintf('Sampling rate: %d Hz', fs);
            sprintf('Mean half‑width: %s', half_width_str);
            sprintf('Mean firing rate: %.2f Hz', mean_firing_rate);
            sprintf('Total time span: %.2f s', ts(end)-ts(1));
            sprintf('Number of timestamps: %d', length(ts));
        };

        text(0.1, 0.9, info_text, 'FontSize', 11, 'VerticalAlignment', 'top');
        title('Parameter Summary');

        sgtitle(sprintf('Average Spike Parameter Analysis (n=%d)', size(wave, 1)));
    end
end