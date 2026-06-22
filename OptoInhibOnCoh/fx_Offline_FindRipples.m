function [ripples] = fx_Offline_FindRipples(data,timestamps,thresholds,durations,frequency,passband)
%FindRipples - Find hippocampal ripples (100~200Hz oscillations).
% INPUTS
%    lfp            input data
%	 timestamps	    timestamps
%    thresholds     thresholds for ripple beginning/end and peak
%    durations      min inter-ripple interval and max ripple duration
%    frequency      sampling rate
%    passband       pass frequency range.
%
% OUTPUT
%    ripples.timestamps        start/stop times for each ripple
%           .peaks             peak power timestamps 
%           .stdev             standard dev used as threshold
%           .peakNormedPower   Nx1 matrix of peak power values

%%
[signal,~,~]= fx_Filter_and_HilbertTransform(double(data),passband,3,1250);
lowThresholdFactor=thresholds(1);
highThresholdFactor=thresholds(2);
minInterRippleInterval=durations(1);
maxRippleDuration=durations(2);


%% detector
% Square and normalize signal
squaredSignal = signal.^2;
windowLength=11;
window = ones(windowLength,1)/windowLength;
keep = [];keep = logical(keep); 
[normalizedSquaredSignal,sd] = fx_unity(fx_Filter0(window,sum(squaredSignal,2)),[],keep);


% 1_Detect ripple periods by thresholding normalized squared signal
thresholded = normalizedSquaredSignal > lowThresholdFactor;
start = find(diff(thresholded)>0);
stop = find(diff(thresholded)<0);
if length(stop) == length(start)-1
	start = start(1:end-1);
end
if length(stop)-1 == length(start)
    stop = stop(2:end);
end
if start(1) > stop(1)
	stop(1) = [];
	start(end) = [];
end
firstPass = [start,stop];
disp(['After detection by thresholding: ' num2str(length(firstPass)) ' events.']);


% 2_Merge ripples if inter-ripple period is too short
minInterRippleSamples = minInterRippleInterval/1000*frequency;
secondPass = [];
ripple = firstPass(1,:);
for i = 2:size(firstPass,1)
	if firstPass(i,1) - ripple(2) < minInterRippleSamples
		% Merge
		ripple = [ripple(1) firstPass(i,2)];
	else
		secondPass = [secondPass ; ripple]; %#ok<*AGROW>
		ripple = firstPass(i,:);
	end
end
secondPass = [secondPass ; ripple];
disp(['After ripple merge: ' num2str(length(secondPass)) ' events.']);


% 3_Discard ripples with a peak power < highThresholdFactor
thirdPass = [];
peakNormalizedPower = [];
for i = 1:size(secondPass,1)
	[maxValue,~] = max(normalizedSquaredSignal([secondPass(i,1):secondPass(i,2)]));
	if maxValue > highThresholdFactor
		thirdPass = [thirdPass ; secondPass(i,:)];
		peakNormalizedPower = [peakNormalizedPower ; maxValue];
	end
end
disp(['After peak thresholding: ' num2str(length(thirdPass)) ' events.']);
peakPosition = zeros(size(thirdPass,1),1);
for i=1:size(thirdPass,1)
	[~,minIndex] = min(signal(thirdPass(i,1):thirdPass(i,2)));
	peakPosition(i) = minIndex + thirdPass(i,1) - 1;
end

% 4_Discard ripples that are way too long
ripples = [timestamps(thirdPass(:,1)) timestamps(peakPosition) ...
           timestamps(thirdPass(:,2)) peakNormalizedPower];
duration = ripples(:,3)-ripples(:,1);
ripples(duration>maxRippleDuration/1000,:) = [];
disp(['After duration test: ' num2str(size(ripples,1)) ' events.']);

%% Output
rips = ripples; clear ripples
ripples.timestamps = rips(:,[1 3]);
ripples.peaks = rips(:,2);            
ripples.peakNormedPower = rips(:,4);
ripples.stdev = sd;