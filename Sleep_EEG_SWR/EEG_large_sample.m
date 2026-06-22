%% EEG_large_sample.m
% This script loads EEG, LFP, and state label data for a specific animal
% and day, then generates several figures:
%   1) A zoomed-in spectrogram around a specific time point (SWR event or arbitrary).
%   2) A full EEG spectrogram over the entire recording.
%   3) A multi-panel figure showing state labels, spectrogram, EEG trace, and EMG.
%
% It relies on precomputed structures from 'full_response_experiment_datapath.mat'
% and uses custom functions: standardizeSR, createSpectrogram, AccuSleep_colormap.

clear; clc;

% Load the master experiment structure
load('Y:\数据备份\AAA_response\A_response_data_sum\full_response_experiment_datapath.mat');

% Select animal and day
animalIdx = 1;          % Animal index
dayIdx = 1;             % Day index
HPC_i = 36;             % Hippocampus channel for SWR reference
ii = 833;               % Window number (for time alignment)

% Extract folder names and paths
fold_name = experiment.Animals{animalIdx}.Days(dayIdx).LFP_AI_foldname;
LFP_AI_path = experiment.Animals{animalIdx}.Days(dayIdx).LFP_AI_path;
labels_state = experiment.Animals{animalIdx}.Days(dayIdx).State_all_data';

%% ---- Zoomed-in Spectrogram around a specific time ----
% Load a PFC or HPC channel (here FP62)
load([LFP_AI_path, 'FP62']);
EEG = tempFP;
EEG = EEG - mean(EEG);             % Remove DC offset

epochLen = 0.2;                    % Window length for spectrogram (seconds)
SR = 1000;                         % Original sampling rate
targetSR = 128;                    % Target sampling rate for downsampling

% Resample to 128 Hz
EEG_resampled = standardizeSR(EEG, SR, targetSR);

% Compute spectrogram using multi-taper method
[spec, tAxis, fAxis] = createSpectrogram(EEG_resampled, targetSR, epochLen);

% Restrict display to frequencies ≤ 30 Hz
showFreqs = find(fAxis <= 30);
spectrogram_display = spec(:, showFreqs)';
fAxis_display = fAxis(showFreqs);

% Use AccuSleep colormap
colormap_data = AccuSleep_colormap();

% Define a specific time range around a point (e.g., SWR peak at tempRs = 1e6 ms)
tempRs = 1000000;   % Example: 1,000,000 ms
time_indices = find(tAxis >= (tempRs - 100000)/1000 & tAxis <= (tempRs + 100000)/1000);

% Set color axis range using percentile
specSample = reshape(spectrogram_display(:, time_indices(1):time_indices(end)), 1, []);
caxis_range = prctile(specSample, [6 98]);

% Plot the zoomed spectrogram
imagesc(time_indices, fAxis_display, spectrogram_display(:,time_indices(1):time_indices(end)), caxis_range);
ylim([0 30]);
axis xy;
colormap(gca, colormap_data);
colorbar;
set(gca,'TickDir','out');
ylabel('Frequency (Hz)', 'FontSize', 12);

%% ---- Full-spectrum EEG Spectrogram ----
% Load a different channel (FP64) for full recording
load([LFP_AI_path, 'FP64']);
EEG = tempFP;
EEG = EEG - mean(EEG);

epochLen = 2;          % Longer window for smoother full spectrogram

% Resample and compute spectrogram (same as above)
EEG_resampled = standardizeSR(EEG, SR, targetSR);
[spec, tAxis, fAxis] = createSpectrogram(EEG_resampled, targetSR, epochLen);
showFreqs = find(fAxis <= 30);
spectrogram_display = spec(:, showFreqs)';
fAxis_display = fAxis(showFreqs);
colormap_data = AccuSleep_colormap();
specTs = (1:size(spec,1)) * epochLen - epochLen/2;   % Time axis in seconds
specTh = specTs / 3600;                              % Time axis in hours

% Set color axis
specSample = reshape(spectrogram_display(:, randperm(size(spectrogram_display,2), ...
    min(round(size(spectrogram_display,2)/10), 1000))), 1, []);
caxis_range = prctile(specSample, [6 98]);

% Plot full spectrogram
figure;
imagesc(specTs, fAxis_display, spectrogram_display, caxis_range);
axis xy;
colormap(colormap_data);
colorbar;
ylabel('Frequency (Hz)', 'FontSize', 12);
title(sprintf('EEG Spectrogram (Epoch Length: %.1fs)', epochLen), 'FontSize', 14);
hold on;
y_lim = ylim;
plot([1 1], y_lim, 'r-', 'LineWidth', 1.5);   % Mark 1 second
hold off;

%% ---- Multi-panel figure: State, Spectrogram, EEG, EMG ----
% Load FP63 as EMG and FP64 as EEG
load([LFP_AI_path, 'FP63']);
EMG = tempFP;
load([LFP_AI_path, 'FP64']);
EEG = tempFP;
EEG = EEG - mean(EEG);

% Compute spectrogram with 2‑s window
epochLen = 2;
EEG_resampled = standardizeSR(EEG, SR, targetSR);
[spec, tAxis, fAxis] = createSpectrogram(EEG_resampled, targetSR, epochLen);
showFreqs = find(fAxis <= 30);
spectrogram_display = spec(:, showFreqs)';
fAxis_display = fAxis(showFreqs);
colormap_data = AccuSleep_colormap();
specTs = (1:size(spec,1)) * epochLen - epochLen/2;
specSample = reshape(spectrogram_display(:, randperm(size(spectrogram_display,2), ...
    min(round(size(spectrogram_display,2)/10), 1000))), 1, []);
caxis_range = prctile(specSample, [6 98]);

% Create figure with 4 subplots
figure('Position', [100, 100, 1200, 800]);

% 1. State labels
ax1 = subplot(4, 1, 1);
plot(labels_state, 'k-', 'LineWidth', 1);
ylabel('State', 'FontSize', 10);
title('Labels State', 'FontSize', 12);
xlim([1, length(labels_state)]);
grid on;

% 2. Spectrogram
ax2 = subplot(4, 1, 2);
imagesc(specTs, fAxis_display, spectrogram_display, caxis_range);
axis xy;
colormap(gca, colormap_data);
cb = colorbar;
ylabel(cb, 'Power', 'FontSize', 8);
ylabel('Frequency (Hz)', 'FontSize', 10);
title(sprintf('EEG Spectrogram (Epoch Length: %.1fs)', epochLen), 'FontSize', 12);

% 3. EEG trace
ax3 = subplot(4, 1, 3);
time_axis_eeg = (0:length(EEG)-1)/SR;
plot(time_axis_eeg, EEG, 'b-', 'LineWidth', 0.5);
ylabel('EEG Amplitude', 'FontSize', 10);
title('EEG Trace', 'FontSize', 12);
grid on;

% 4. EMG trace
ax4 = subplot(4, 1, 4);
if exist('EMG', 'var') && length(EMG) == length(EEG)
    time_axis_emg = (0:length(EMG)-1)/SR;
    plot(time_axis_emg, EMG, 'g-', 'LineWidth', 0.5);
else
    text(0.5, 0.5, 'No EMG data available', 'HorizontalAlignment', 'center');
end
ylabel('EMG Amplitude', 'FontSize', 10);
title('EMG Trace', 'FontSize', 12);
xlabel('Time (s)', 'FontSize', 10);
grid on;

sgtitle('Multi-Signal Analysis', 'FontSize', 14, 'FontWeight', 'bold');

% Save the figure
filename = sprintf('EEG_animal%d_day%d.eps', animalIdx, dayIdx);
print(gcf, '-depsc', '-painters', '-r300', filename);