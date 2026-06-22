function [resultTable, allGroups] = processTsWaveData(tsList, ts, wave)
% processTsWaveData: Process spike unit data, group by 4‑channel blocks,
%   select the unit with the largest waveform amplitude range per group,
%   and compile results into a table.
%
%   This function orchestrates the entire pipeline:
%       1. Groups unit names (tsList) using groupTSList.
%       2. For each group, calls selectChannelsByWaveAmplitude to find the
%          best unit (largest peak‑to‑peak amplitude).
%       3. For each selected unit, creates a table row via createResultRow
%          containing metadata, timestamps, waveforms, and summary statistics.
%
%   Inputs:
%       tsList - Cell array of unit names (e.g., 'ts_01_2').
%       ts     - Structure with timestamp vectors (fields like ts_01_2).
%       wave   - Structure with waveform matrices (fields like wave_01_2).
%
%   Outputs:
%       resultTable - A table where each row corresponds to one selected unit,
%                     with columns for unit name, channel, timestamps, waveforms,
%                     and waveform statistics.
%       allGroups   - (Optional) The grouping information returned by groupTSList.

    % Initialise the result table
    resultTable = table();

    % ---- Step 1: Group the units by 4‑channel blocks and waveform groups ----
    [channelGroups, groupInfo] = extractChannelGroups(tsList);
    % Note: extractChannelGroups is likely a wrapper that calls groupTSList.
    % If not available, one can directly use groupTSList and adapt accordingly.
    % For clarity, we assume it returns {channelGroups, groupInfo}.

    % ---- Step 2: Process each group ----
    for groupIdx = 1:length(channelGroups)
        groupChannels = channelGroups{groupIdx};

        if isempty(groupChannels)
            continue;
        end

        fprintf('Processing group %d (channels %02d‑%02d)\n', ...
                groupIdx, min(groupChannels), max(groupChannels));

        % Find the best channel (largest waveform range) in this group
        [bestChannel, bestTsName, bestTsData, bestWaveData] = ...
            findMaxRangeChannelInGroup(groupChannels, tsList, ts, wave);

        % ---- Step 3: Create a row for this selected unit ----
        if ~isempty(bestChannel)
            newRow = createResultRow(bestTsName, bestChannel, bestTsData, bestWaveData);
            resultTable = [resultTable; newRow];
        end
    end

    % ---- Optional: return grouping information ----
    if nargout > 1
        allGroups = groupInfo;
    end
end