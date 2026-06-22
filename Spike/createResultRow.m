function newRow = createResultRow(tsName, channelNum, tsData, waveData)
% createResultRow: Create a table row summarising spike unit information.
%
%   This function takes a spike unit's name, channel number, timestamp vector,
%   and waveform matrix, and packages them into a single table row with
%   additional metadata (channel as string, experiment number, timestamp,
%   waveform statistics) for easy storage in a results table.
%
%   Inputs:
%       tsName     - String or character vector, e.g., 'ts_01_0' (unit name).
%       channelNum - Numeric channel index (e.g., 1, 33).
%       tsData     - Vector of spike timestamps (seconds).
%       waveData   - n×32 matrix of spike waveforms (mV), each row is one waveform.
%
%   Output:
%       newRow     - A table with one row containing all the fields.

    % ---- Format channel number as a two‑digit string ----
    channelStr = sprintf('%02d', channelNum);

    % ---- Extract experiment number from tsName ----
    % Expected format: 'ts_XX_Y' where XX is channel (ignored) and Y is experiment/unit number.
    pattern = 'ts_(\d+)_(\d+)';
    tokens = regexp(tsName, pattern, 'tokens');

    if ~isempty(tokens)
        expNum = tokens{1}{2};   % Second captured group (the unit number)
    else
        expNum = '1';            % Fallback if pattern does not match
    end

    % ---- Assemble the table row ----
    newRow = table();
    newRow.tsName        = {tsName};                     % Unit name as a cell string
    newRow.channel       = channelNum;                   % Numeric channel
    newRow.channelStr    = {channelStr};                 % Two‑digit channel string
    newRow.experimentNum = str2double(expNum);           % Numeric unit/experiment number
    newRow.tsData        = {tsData};                     % Timestamp vector (stored in cell)
    newRow.waveData      = {waveData};                   % Waveform matrix (stored in cell)
    newRow.tsLength      = length(tsData);               % Number of spikes
    newRow.waveSize      = {size(waveData)};             % Dimensions of waveform matrix
    newRow.timestamp     = datetime('now');              % Time of creation

    % ---- Compute summary statistics from the mean waveform ----
    if ~isempty(waveData)
        meanWave = mean(waveData, 1);                    % Average waveform across spikes
        newRow.waveRange  = range(meanWave);             % Peak‑to‑peak amplitude
        newRow.waveMean   = mean(meanWave);              % Mean of the average waveform
        newRow.waveStd    = std(meanWave);               % Standard deviation of average waveform
        newRow.waveMax    = max(meanWave);               % Maximum value
        newRow.waveMin    = min(meanWave);               % Minimum value
    end
end