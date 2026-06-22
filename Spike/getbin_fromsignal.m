function binned_array = getbin_fromsignal(trigger_times, event_positions, pre_points, post_points)
% getbin_fromsignal: Analyze the distribution of events around trigger times.
%   This function computes event counts at each relative time point within a
%   window around each trigger event. It outputs a binned summary of the total
%   event counts across time bins.
%
%   Inputs:
%       trigger_times   : Vector of trigger event positions (indices in the same
%                         time base as event_positions).
%       event_positions : Vector of event positions (e.g., spike times in samples).
%       pre_points      : Number of time points to include before each trigger.
%       post_points     : Number of time points to include after each trigger.
%
%   Output:
%       binned_array    : A 70-element vector where each element is the sum of
%                         event counts over 10 consecutive time points (bins).
%                         The total window length is pre_points + post_points + 1
%                         (typically 701 points if pre=300, post=400).
%
%   Algorithm:
%       1. For each trigger, define a window [trigger - pre_points, trigger + post_points].
%       2. Keep only triggers whose window falls within the valid event range.
%       3. Count how many events occur at each relative time point (relative to trigger).
%       4. Compute summary statistics across all valid triggers.
%       5. Sum the event counts across bins of 10 consecutive time points and return.

    % Get number of triggers and total window size
    num_triggers = length(trigger_times);
    total_window = pre_points + post_points + 1;          % Total time points per window
    time_axis = -pre_points:post_points;                  % Relative time indices

    % Initialize matrix to store event counts for each trigger and each time point
    event_matrix = zeros(num_triggers, total_window);
    valid_triggers = [];   % Indices of triggers that are within bounds

    % ---- Loop over each trigger ----
    for i = 1:num_triggers
        trigger_pos = trigger_times(i);
        window_start = trigger_pos - pre_points;
        window_end = trigger_pos + post_points;

        % Check that the window is entirely within the valid event range
        if window_start >= 1 && window_end <= max(event_positions)
            valid_triggers = [valid_triggers; i];

            % Find all events that fall within this window
            events_in_window = event_positions(event_positions >= window_start & event_positions <= window_end);

            % Compute time of each event relative to the trigger
            relative_times = events_in_window - trigger_pos;

            % Count how many events occur at each relative time point
            for t = 1:total_window
                current_time = time_axis(t);
                event_matrix(i, t) = sum(relative_times == current_time);
            end
        end
    end

    % Report how many triggers were valid
    fprintf('Valid triggers: %d/%d\n', length(valid_triggers), num_triggers);

    % Keep only the valid trigger rows
    event_matrix = event_matrix(valid_triggers, :);

    % ---- Compute pointwise statistics across all valid triggers ----
    pointwise_stats = struct();
    pointwise_stats.time_axis = time_axis;                                % Relative time axis
    pointwise_stats.mean_events = mean(event_matrix, 1);                  % Mean across triggers
    pointwise_stats.std_events = std(event_matrix, 0, 1);                 % Standard deviation
    pointwise_stats.sem_events = pointwise_stats.std_events / sqrt(size(event_matrix, 1)); % Standard error
    pointwise_stats.median_events = median(event_matrix, 1);              % Median across triggers
    pointwise_stats.sum_events = sum(event_matrix, 1);                    % Total events across all triggers

    % Probability that an event occurs at this time point in any given trigger
    pointwise_stats.event_probability = mean(event_matrix > 0, 1);

    % Find the peak of the mean event count and its location
    [max_events, max_idx] = max(pointwise_stats.mean_events);
    pointwise_stats.peak_time = time_axis(max_idx);
    pointwise_stats.peak_events = max_events;

    % ---- Bin the summed event counts into 70 bins of 10 time points each ----
    % This is useful for reducing dimensionality and smoothing the output.
    num_bins = 70;   % 70 bins ¡Á 10 points/bin = 700 points (fits within 701 total window)
    binned_array = zeros(num_bins, 1);

    for i = 1:num_bins
        start_idx = (i - 1) * 10 + 1;
        end_idx = i * 10;
        binned_array(i) = sum(pointwise_stats.sum_events(start_idx:end_idx));
    end

end