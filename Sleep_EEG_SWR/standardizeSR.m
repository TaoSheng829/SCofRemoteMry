function x = standardizeSR(x, oldSR, newSR)
% standardizeSR: Resample a signal to a new sampling rate without warnings.
%   This is a simple down‑/up‑sampling by taking every (oldSR/newSR)-th sample.
%   It suppresses the non‑integer colon warning.
%
%   Inputs:
%       x      : 1‑D signal vector.
%       oldSR  : Original sampling rate (Hz).
%       newSR  : Target sampling rate (Hz).
%   Output:
%       x      : Resampled signal.

warning('off','MATLAB:colon:nonIntegerIndex');
x = x(1:(oldSR/newSR):end);
warning('on','MATLAB:colon:nonIntegerIndex');
end