function selectedChannels = selectChannelsByWaveAmplitude(groupedData, ts, wave)
% selectChannelsByWaveAmplitude: For each group, select the channel with the
%   largest waveform amplitude range (max‑min) and return its unit name.
%
%   This function processes pre‑grouped data (output of groupTSList) and,
%   for each group of 4 units, extracts the waveform data, computes the
%   peak‑to‑peak amplitude (max‑min) of the mean waveform, and selects the
%   unit with the largest amplitude range. It returns a list of selected
%   unit names, one per group.
%
%   Inputs:
%       groupedData - Cell array, each element is a 1×4 cell array of unit
%                     names (e.g., {'ts_01_2', 'ts_02_2', 'ts_03_2', 'ts_04_2'}).
%       ts          - Structure containing timestamp data for each unit
%                     (field names like 'ts_01_2').
%       wave        - Structure containing waveform data for each unit
%                     (field names like 'wave_01_2').
%   Output:
%       selectedChannels - Cell array of unit names (one per group) that have
%                          the largest amplitude range within their group.

    % Initialize output
    selectedChannels = {};

    % Loop over each group
    for groupIdx = 1:length(groupedData)
        group = groupedData{groupIdx};

        % Preallocate arrays for storing metrics for each channel in the group
        maxMinDiffs = zeros(length(group), 1);   % Peak‑to‑peak amplitude range
        avgValues = zeros(length(group), 1);     % Mean of the waveform (for display)

        % Loop over each channel in the group
        for chanIdx = 1:length(group)
            chanName = group{chanIdx};

            % Construct the waveform field name by replacing 'ts_' with 'wave_'
            waveFieldName = strrep(chanName, 'ts_', 'wave_');

            % Retrieve waveform data
            if isfield(wave, waveFieldName)
                waveData = wave.(waveFieldName);

                % Ensure it is numeric
                if isnumeric(waveData)
                    % Convert to column vector for consistency
                    waveData = waveData(:);

                    % Compute mean value (scalar) – for display only
                    avgValues(chanIdx) = mean(waveData);

                    % Compute peak‑to‑peak amplitude range
                    maxMinDiffs(chanIdx) = max(waveData) - min(waveData);
                else
                    warning('Waveform data for %s is not numeric.', waveFieldName);
                    avgValues(chanIdx) = NaN;
                    maxMinDiffs(chanIdx) = NaN;
                end
            else
                warning('Waveform field %s not found.', waveFieldName);
                avgValues(chanIdx) = NaN;
                maxMinDiffs(chanIdx) = NaN;
            end
        end

        % Find the channel with the maximum amplitude range
        [maxDiff, maxDiffIdx] = max(maxMinDiffs);

        % If multiple channels share the same max value, pick the first one
        if length(maxDiffIdx) > 1
            maxDiffIdx = maxDiffIdx(1);
        end

        % Select that channel
        selectedChannel = group{maxDiffIdx};
        selectedChannels{end+1} = selectedChannel;

        % Display selection information (for debugging)
        fprintf('Group %d: selected channel %s\n', groupIdx, selectedChannel);
        fprintf('  Channel waveform means: ');
        for i = 1:length(avgValues)
            fprintf('%.4f ', avgValues(i));
        end
        fprintf('\n');
        fprintf('  Channel amplitude ranges: ');
        for i = 1:length(maxMinDiffs)
            fprintf('%.4f ', maxMinDiffs(i));
        end
        fprintf('\n');
        fprintf('  Max amplitude range: %.4f\n\n', maxDiff);
    end

    % Print final selected channels
    fprintf('=== Final selected channels ===\n');
    for i = 1:length(selectedChannels)
        fprintf('Group %d: %s\n', i, selectedChannels{i});
    end
end