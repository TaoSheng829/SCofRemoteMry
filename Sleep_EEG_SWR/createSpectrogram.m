function [s, t, f] = createSpectrogram(EEG, SR, winstep)
% createSpectrogram: Compute a multi‑taper spectrogram of EEG data.
%   This function uses the multi‑taper method (via mtspecgramc) to generate
%   a time‑frequency representation. The EEG is resampled? (No, it assumes
%   SR is the sampling rate of the input EEG). The window is set to at least
%   5 seconds, and the frequency axis is downsampled to 0.2‑Hz steps if
%   the window exceeds 5 seconds.
%
%   Inputs:
%       EEG      : 1‑D signal (row vector preferred).
%       SR       : Sampling rate (Hz).
%       winstep  : Step size (seconds) for consecutive windows.
%
%   Outputs:
%       s        : Spectrogram matrix (time × frequency).
%       t        : Time axis (seconds) for each bin.
%       f        : Frequency axis (Hz).

% Ensure EEG is a row vector
if ~isrow(EEG)
    EEG = EEG';
end

window = max([5, winstep]);   % Window length (seconds)

% Truncate to a multiple of SR*winstep
EEG = EEG(1:(length(EEG)-mod(length(EEG), SR*winstep)));

% Pad the signal so that the first bin starts at time 0
pad_len = round(SR * (window - winstep) / 2);
EEG = [EEG(1:pad_len), EEG, EEG((end-pad_len+1):end)];

% Parameters for multi‑taper spectrogram
params = struct;
params.pad = -1;
params.Fs = SR;
params.fpass = [0 64];
params.tapers = [3 5];

% Compute spectrogram (using mtspecgramc from Chronux toolbox)
[s, t, f] = mtspecgramc(EEG, [window, winstep], params);

% Adjust time axis to reflect padding
t = t - (window - winstep)/2;

% If window > 5, downsample frequency axis to 0.2‑Hz steps
if window > 5
    fTarget = 0:0.2:64;
    fIdx = zeros(1, length(fTarget));
    for i = 1:length(fTarget)
        [~, fIdx(i)] = min(abs(f - fTarget(i)));
    end
    f = fTarget;
    s = s(:, fIdx);
end
end