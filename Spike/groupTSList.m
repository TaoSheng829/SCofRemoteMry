function groupedData = groupTSList(tsList)
% groupTSList: Group spike unit names by channel and waveform group.
%
%   This function takes a cell array of spike unit names (e.g., 'ts_01_2')
%   and groups them into blocks of 4 consecutive channels (e.g., 01‑04, 05‑08,
%   ..., 29‑32) that share the same waveform group number (the second number
%   in the unit name). It returns a cell array where each cell contains the
%   names of the 4 units belonging to one such group.
%
%   Input:
%       tsList - Cell array of strings, each like 'ts_XX_Y', where XX is the
%                channel number (01‑64) and Y is the waveform group/unit number.
%   Output:
%       groupedData - Cell array, each element is a 1×4 cell array of unit names
%                     belonging to the same 4‑channel block and same waveform group.

    % Initialize output
    groupedData = {};
    groupIndex = 1;

    % Extract channel numbers and waveform group numbers from all names
    channels = zeros(length(tsList), 1);
    waveforms = zeros(length(tsList), 1);

    for i = 1:length(tsList)
        name = tsList{i};
        % Extract all numeric substrings using regex
        nums = regexp(name, '\d+', 'match');
        if length(nums) >= 2
            channels(i) = str2double(nums{1});   % First number: channel
            waveforms(i) = str2double(nums{2});  % Second number: waveform group
        end
    end

    % Find all unique waveform groups
    uniqueWaveforms = unique(waveforms);

    % Loop over each waveform group
    for wfIdx = 1:length(uniqueWaveforms)
        wf = uniqueWaveforms(wfIdx);

        % Find indices belonging to this waveform group
        wfIndices = find(waveforms == wf);

        % Get corresponding channel numbers and names
        wfChannels = channels(wfIndices);
        wfNames = tsList(wfIndices);

        % Sort by channel number
        [sortedChannels, sortOrder] = sort(wfChannels);
        sortedNames = wfNames(sortOrder);

        % Group into blocks of 4 consecutive channels
        i = 1;
        while i <= length(sortedChannels) - 3
            % Check if the next 4 channels are consecutive (difference = 1)
            if all(diff(sortedChannels(i:i+3)) == 1)
                startChan = sortedChannels(i);
                endChan = sortedChannels(i+3);

                % Verify that the block aligns with 01‑04, 05‑08, ..., 29‑32
                blockNum = ceil(startChan / 4);
                expectedStart = (blockNum - 1) * 4 + 1;
                expectedEnd = blockNum * 4;

                if startChan == expectedStart && endChan == expectedEnd
                    % Store this group
                    groupedData{groupIndex} = sortedNames(i:i+3);

                    % Display grouping info (for debugging)
                    fprintf('Group %d: channels %02d‑%02d, waveform group %d\n', ...
                            groupIndex, startChan, endChan, wf);
                    fprintf('    Contains: %s\n', strjoin(sortedNames(i:i+3), ', '));
                    fprintf('\n');

                    groupIndex = groupIndex + 1;
                    i = i + 4;   % Skip these 4 channels
                else
                    i = i + 1;   % Not a valid block, move one step
                end
            else
                i = i + 1;
            end
        end
    end

    fprintf('Total groups found: %d\n', groupIndex - 1);

    % Warn if no groups were found
    if groupIndex == 1
        warning('No valid groups found.');
    end
end