%% spikeProInd.m: Compute spike property indices for clustering
% This script extracts two features from spike data:
%   1. Half‑width (μs) – derived from the mean waveform
%   2. Firing rate (Hz) – spikes per second
% It then performs K‑means clustering on these features.

%% ===================== a1: Initialise storage =============================
HalfwaveMean = [];   % Half‑width values (μs)
SpikeRateMean = [];  % Firing rates (Hz)

%% ===================== a2: Extract features for each unit =================
% This assumes variables 'tsList', 'ts', and 'wave' are already in the workspace.
for i = 1:length(tsList)
    % ---- Firing rate ----
    eval(['tempts = ts.', char(tsList(i)), ';']);
    temptsMean = length(tempts);
    SR = temptsMean / (max(tempts) - min(tempts));   % Spikes per second
    SpikeRateMean = [SpikeRateMean, SR];

    % ---- Half‑width (time from min to max in mean waveform) ----
    eval(['tempwave = wave.', strrep(char(tsList(i)), 'ts', 'wave'), ';']);
    tempwaveMean = mean(tempwave);                    % Mean waveform (1×32)

    % Find index of minimum and maximum; compute half‑width in μs
    % Assuming 33.33 μs per sample (i.e., 30 kHz sampling rate)
    tempHalfwaveMean = abs(find(tempwaveMean == max(tempwaveMean)) - ...
                           find(tempwaveMean == min(tempwaveMean))) * 33.33;
    HalfwaveMean = [HalfwaveMean, tempHalfwaveMean];
end

%% ===================== a3: K‑means clustering =============================
% Cluster units into two groups based on half‑width and firing rate.
X = [HalfwaveMean; SpikeRateMean]';

opts = statset('Display', 'final');
[idx, C] = kmeans(X, 2, 'Distance', 'sqeuclidean', ...
    'Replicates', 5, 'Options', opts);

% Visualise the clusters
figure;
plot(X(idx == 1, 1), X(idx == 1, 2), 'r.', 'Marker', 'o');
hold on;
plot(X(idx == 2, 1), X(idx == 2, 2), 'b.', 'Marker', 'o');
plot(C(:, 1), C(:, 2), 'kx', 'MarkerSize', 15, 'LineWidth', 3);
legend('Cluster 1', 'Cluster 2', 'Centroids', 'Location', 'NW');
title('Cluster Assignments and Centroids');
hold off;

% xlim([0,1]); ylim([0,0.3]);   % (Optional) adjust axes