function plotEEGSpectrogram(EEG, fs, varargin)
% plotEEGSpectrogram: Plot a time-frequency spectrogram of an EEG signal.
%   This function generates a figure with a spectrogram of the given EEG
%   signal. It optionally allows specification of time range, frequency limit,
%   window length, colormap, brightness, and display of colorbar.
%
%   Inputs:
%       EEG      : 1‑D vector of EEG data.
%       fs       : Sampling rate (Hz).
%       varargin : Optional parameter-value pairs:
%           'startTime'   : Start time (s) for display (default: 0).
%           'duration'    : Duration (s) to display (default: full length).
%           'freqLimit'   : Maximum frequency (Hz) to show (default: 30).
%           'epochLen'    : Window length (s) for spectrogram (default: 4).
%           'colormap'    : Colormap name (default: 'parula').
%           'brightness'  : Brightness scaling (default: 1).
%           'showColorbar': Logical (default: true).

    % Parse input parameters
    p = inputParser;
    addParameter(p, 'startTime', 0, @isnumeric);
    addParameter(p, 'duration', length(EEG)/1000, @isnumeric);
    addParameter(p, 'freqLimit', 30, @isnumeric);
    addParameter(p, 'epochLen', 4, @isnumeric);
    addParameter(p, 'colormap', 'parula', @ischar);
    addParameter(p, 'brightness', 1, @isnumeric);
    addParameter(p, 'showColorbar', true, @islogical);
    parse(p, varargin{:});

    startTime = p.Results.startTime;
    duration = p.Results.duration;
    freqLimit = p.Results.freqLimit;
    epochLen = p.Results.epochLen;
    colormapName = p.Results.colormap;
    brightness = p.Results.brightness;
    showColorbar = p.Results.showColorbar;

    % Check Nyquist limit
    if freqLimit > fs/2
        warning('Frequency limit adjusted to Nyquist (%.1f Hz)', fs/2);
        freqLimit = fs/2;
    end

    totalTime = length(EEG) / fs;

    % Adjust duration if it exceeds total time
    if startTime + duration > totalTime
        duration = totalTime - startTime;
        if duration <= 0
            error('Start time exceeds data range.');
        end
    end

    % Extract the segment
    startIdx = round(startTime * fs) + 1;
    endIdx = min(round((startTime + duration) * fs), length(EEG));
    EEG_segment = EEG(startIdx:endIdx);

    % Resample to 128 Hz (standard for EEG sleep analysis)
    standardizedSR = 128;
    if fs ~= standardizedSR
        EEG_resampled = resample(EEG_segment, standardizedSR, fs);
    else
        EEG_resampled = EEG_segment;
    end

    % Spectrogram parameters (following AccuSleep conventions)
    window = standardizedSR;          % 1‑s window
    noverlap = round(window * 0.5);   % 50% overlap
    nfft = 2^nextpow2(window);

    % Compute spectrogram
    [spec, f, t] = spectrogram(EEG_resampled, window, noverlap, nfft, standardizedSR);
    spec_db = 10*log10(abs(spec) + eps);

    % Adjust time axis to original start
    t = t + startTime;

    % Restrict frequency range
    freqIdx = f <= freqLimit;
    spec_display = spec_db(freqIdx, :);
    f_display = f(freqIdx);

    % Set color axis using percentiles
    specSample = reshape(spec_display, 1, []);
    caxis_range = prctile(specSample, [6 98]);
    caxis_range(2) = caxis_range(2) * brightness;

    % Create figure
    figure('Position', [100, 100, 1200, 500], 'Color', 'w');

    % Plot spectrogram
    imagesc(t, f_display, spec_display, caxis_range);
    axis xy;
    colormap(gca, colormapName);

    xlim([t(1), t(end)]);
    ylim([0, freqLimit]);
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title(sprintf('EEG Spectrogram (%.1f-%.1f s, %.1f s duration)', ...
                  startTime, startTime+duration, duration));
    yticks(0:5:freqLimit);

    if showColorbar
        cb = colorbar;
        cb.Label.String = 'Power (dB)';
    end

    % Add information text
    infoStr = sprintf('Sampling Rate: %g Hz | Resampled to: %g Hz | Total duration: %.2f s', ...
                      fs, standardizedSR, totalTime);
    annotation('textbox', [0.1, 0.01, 0.8, 0.04], ...
               'String', infoStr, 'EdgeColor', 'none', ...
               'HorizontalAlignment', 'center', 'FontSize', 10);

    set(gca, 'FontSize', 11, 'LineWidth', 1.5);
end