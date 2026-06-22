function lag_vector = St_GetLagVector(eventtime, phase)
% St_GetLagVector: Compute phase-phase coupling (PPC) across a range of time lags.
%   This function takes a set of event times (e.g., spike times) and a continuous
%   phase signal (e.g., from an LFP filter). For each lag from -40 ms to +40 ms
%   (in steps of 4 ms), it shifts the event times by that lag, extracts the
%   corresponding phase values, and computes the circular mean resultant length
%   (PPC) of those phases. The resulting PPC values are returned as a 1x21 vector.
%
%   Inputs:
%       eventtime : Vector of event timestamps (in seconds). Typically spike times.
%                   Example: eventtime = ts_List{20};
%       phase     : Phase time series sampled at 1000 Hz (length = signal duration * 1000).
%                   The phase values should be in radians, typically between -π and π.
%
%   Output:
%       lag_vector : 1x21 vector containing PPC values for lags from -40 ms to +40 ms,
%                    with a step of 4 ms. Index 1 corresponds to -40 ms, index 21 to +40 ms.
%
%   Algorithm:
%       1. For each lag (delta_t), shift the event times by delta_t (converted to seconds).
%       2. Remove events that fall outside the valid phase range (0 to length(phase)/1000).
%       3. For each shifted event, extract the phase value at the nearest millisecond.
%       4. Compute the PPC (mean resultant length) of the extracted phase values.
%       5. Store the result in the corresponding position of the lag_vector.

% Preallocate the output vector (21 lags from -40 to 40 ms, step 4 ms)
lag_vector = zeros(1, 21);

% Define the range of time lags (in milliseconds) and step size
for delta_t = -40 : 4 : 40
    % Shift event times by the current lag (convert ms to seconds)
    temp_eventtime = eventtime + delta_t / 1000;

    % Remove events that fall outside the valid phase time range
    % The phase vector is assumed to span from time 0 to (length(phase)/1000) seconds.
    % We remove events with time < 0 or time >= length(phase)/1000 (i.e., beyond the last sample).
    temp_f1 = find(temp_eventtime >= length(phase) / 1000);   % Events at or beyond end
    temp_f2 = find(temp_eventtime <= 0);                     % Events at or before start
    temp_eventtime(temp_f1) = [];
    temp_eventtime(temp_f2) = [];

    temp_len = length(temp_eventtime);
    spike_phase = zeros(1, temp_len);

    % Extract the phase value at each shifted event time
    % Round to the nearest millisecond index (phase is sampled at 1000 Hz)
    for i = 1:temp_len
        spike_phase(i) = phase(round(temp_eventtime(i) * 1000));
    end

    % Compute the phase-phase coupling (PPC) as the mean resultant length
    % of the circular phase values. The function 'ppc' is assumed to be
    % defined elsewhere (e.g., computes |mean(exp(1i*phase))|).
    % Store the result at the corresponding position in the output vector.
    % Index mapping: delta_t = -40 -> 1, -36 -> 2, ..., 40 -> 21.
    lag_vector(1, (delta_t + 40) / 4 + 1) = ppc(spike_phase);
end

end