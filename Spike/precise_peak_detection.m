function positions = precise_peak_detection(signal, baseline_max, min_peak_height, target_length)
% precise_peak_detection: Identify signal segments with high-amplitude peaks
%   of a specific duration.
%
%   This function detects contiguous segments in a signal where the value
%   exceeds a threshold (min_peak_height), filters them by length (close to
%   target_length), and additionally checks that the segment's mean amplitude
%   falls within a reasonable range (4000¨C6000) to reject spurious events.
%   It returns the start and end indices of up to 50 valid segments.
%
%   Inputs:
%       signal          : Vector of signal values (e.g., LFP amplitude envelope).
%       baseline_max    : (Not used in the current implementation; retained for
%                         compatibility or future use.)
%       min_peak_height : Threshold above which a sample is considered part of
%                         a "peak" region.
%       target_length   : Desired duration (in samples) of the peak segment.
%                         The algorithm accepts segments with length within
%                         ¡À5 samples of this target.
%
%   Output:
%       positions       : An N¡Á2 matrix where each row contains [start, end]
%                         indices of detected peak segments. At most 50 rows
%                         are returned.

    % ---- Step 1: Binarize the signal ----
    % Create a binary array: 1 where signal exceeds the threshold, 0 otherwise.
    binary_signal = signal > min_peak_height;

    % ---- Step 2: Find all contiguous runs of 1s ----
    % Use diff on padded binary vector to find starts and ends of runs.
    diff_binary = diff([0; binary_signal(:); 0]);
    starts = find(diff_binary == 1);          % Indices where runs begin
    ends   = find(diff_binary == -1) - 1;     % Indices where runs end

    % Compute the length of each run
    lengths = ends - starts + 1;

    % ---- Step 3: Filter runs by length (target_length ¡À tolerance) ----
    length_tol = 5;   % Allowable deviation from target_length
    valid_idx = find(abs(lengths - target_length) <= length_tol);

    % ---- Step 4: Further validate by checking mean amplitude in the segment ----
    % Reject segments whose mean is outside the range [4000, 6000] to avoid
    % false positives due to noise.
    final_positions = [];
    for i = 1:length(valid_idx)
        idx = valid_idx(i);
        seg_data = signal(starts(idx):ends(idx));
        seg_mean = mean(seg_data);

        % Check that the segment's average value lies within the expected range
        if seg_mean > 4000 && seg_mean < 6000   % 5000 ¡À 1000
            final_positions = [final_positions; starts(idx), ends(idx)];
        end

        % Stop early if we already have 50 valid segments (sufficient for most analyses)
        if size(final_positions, 1) >= 50
            break;
        end
    end

    % Return at most the first 50 valid segments (if fewer exist, return all)
    positions = final_positions(1:min(50, end), :);

end