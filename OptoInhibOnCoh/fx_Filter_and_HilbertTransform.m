function [filtered,amp,phase] = fx_Filter_and_HilbertTransform(data,passband,order,Fs)
%wy_Filter_and_HilbertTransform
%INPUT
%     data        data
%     passband    pass frequency range
%     order       filter order
%     Fs          Sampling rate
%
%OUTPUT
%     filtered      filtered data

%%
if passband(1) == 0,
	[b,a] = cheby2(order,20,passband(2)/(Fs/2),'low');
elseif passband(2) == inf
    [b,a] = cheby2(order,20,passband(1)/(Fs/2),'high');
else
	[b,a] = cheby2(order,20,passband/(Fs/2));
end

for i = 1:size(data,2),
    if strcmp(version,'R2017a')
    filtered(:,i) = filtfilt(b,a,double(data(:,i))); %#ok<*AGROW>
    else
    filtered(:,i) = FiltFiltM(b,a,double(data(:,i)));    
    end
    hilb = hilbert(filtered(:,i));
    amp(:,i) = abs(hilb);
    phase(:,i) = angle(hilb);
end
end






