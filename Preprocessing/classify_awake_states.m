function [new_labels, stats] = classify_awake_states(Motion_data, labels, sampling_interval)
% classify_awake_states: Refine awake state labels using motion data.
%   This function takes a vector of motion (activity) data sampled at 1 Hz
%   and a vector of pre‑classified state labels (e.g., REM, Awake, NREM)
%   that are sampled at a lower rate (e.g., every 2.5 seconds). It interpolates
%   the labels to match the 1 Hz motion data, then sub‑classifies the Awake
%   periods into 'Awake_resting' (low motion) and 'Awake_locomotion' (high motion)
%   based on an adaptive threshold computed from the motion variability.
%
%   Inputs:
%       Motion_data      : Vector of motion values (e.g., Cssimval0) sampled at 1 Hz.
%       labels           : Vector of integer state labels (1=REM, 2=Awake, 3=NREM, 4=Invalid),
%                          sampled every 'sampling_interval' seconds.
%       sampling_interval: (Optional) Time interval (in seconds) between label samples.
%                          Default = 2.5 seconds.
%
%   Outputs:
%       new_labels : Vector of refined labels at 1 Hz, where Awake (2) is split into
%                    2.1 (Awake_resting) and 2.2 (Awake_locomotion).
%       stats      : Structure containing count statistics for each state and the
%                    threshold used for classification.

    % Set default sampling interval if not provided
    if nargin < 3
        sampling_interval = 2.5;
    end

    % Ensure data are column vectors for consistency
    Motion_data = Motion_data(:);
    labels = labels(:);

    % Determine lengths of input vectors
    n_motion = length(Motion_data);
    n_labels = length(labels);

    % Display basic information about data lengths
    fprintf('Motion data length: %d points (%.1f seconds)\n', n_motion, n_motion);
    fprintf('Labels data length: %d points (%.1f seconds)\n', n_labels, n_labels * sampling_interval);

    % ---- Interpolate labels to 1 Hz time base ----
    % Original label time points: assume first label corresponds to t = 1 second
    % (this is a common convention; adjust if your data starts at t=0)
    original_time = (0:n_labels-1) * sampling_interval + 1;   % e.g., 1, 3.5, 6.5, ...
    target_time = (1:n_motion)';                              % 1, 2, 3, ... seconds

    % Interpolate using nearest‑neighbor to preserve discrete state values
    labels_interp = interp1(original_time, labels, target_time, 'nearest', 'extrap');

    % ---- Compute motion variability (standard deviation over a sliding window) ----
    window_size = 10;   % 10‑second window (since motion data is 1 Hz)
    motion_std = movstd(Motion_data, window_size);

    % ---- Determine adaptive threshold for locomotion vs. resting ----
    % Use median + median absolute deviation (MAD) as a robust threshold
    threshold = median(motion_std) + mad(motion_std, 1);

    % ---- Create new labels by sub‑classifying Awake periods ----
    new_labels = labels_interp;
    awake_idx = (labels_interp == 2);   % Find all samples originally labelled as Awake

    % Sub‑classify: if motion variability is below threshold → resting (2.1)
    %                if above or equal → locomotion (2.2)
    new_labels(awake_idx & motion_std < threshold) = 2.1;   % Awake_resting
    new_labels(awake_idx & motion_std >= threshold) = 2.2;  % Awake_locomotion

    % ---- Collect summary statistics ----
    stats = struct();
    stats.awake_resting = sum(new_labels == 2.1);
    stats.awake_locomotion = sum(new_labels == 2.2);
    stats.rem = sum(new_labels == 1);
    stats.nrem = sum(new_labels == 3);
    stats.invalid = sum(new_labels == 4);
    stats.threshold = threshold;
    stats.n_total = length(new_labels);

    % Print statistics to the command window
    fprintf('\nClassification results:\n');
    fprintf('  Total points: %d\n', stats.n_total);
    fprintf('  Awake_resting: %d points (%.1f%%)\n', stats.awake_resting, 100*stats.awake_resting/stats.n_total);
    fprintf('  Awake_locomotion: %d points (%.1f%%)\n', stats.awake_locomotion, 100*stats.awake_locomotion/stats.n_total);
    fprintf('  REM: %d points (%.1f%%)\n', stats.rem, 100*stats.rem/stats.n_total);
    fprintf('  NREM: %d points (%.1f%%)\n', stats.nrem, 100*stats.nrem/stats.n_total);
    fprintf('  Invalid: %d points (%.1f%%)\n', stats.invalid, 100*stats.invalid/stats.n_total);

end