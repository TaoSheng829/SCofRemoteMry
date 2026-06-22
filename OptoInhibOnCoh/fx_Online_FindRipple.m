function flag = fx_Online_FindRipple(newdata,thresholds)
%FindRipples - Find hippocampal ripples (100~200Hz oscillations).
% INPUTS
%    newdata        newdata in 8ms
%    thresholds     thresholds for ripple detection
%
% OUTPUT 
%    flag           IsRipple in 8ms
%%
% Update register
global register
len=length(newdata);
register=[register((len+1):length(register)) newdata];

% Caculated standard deviation
rem1=std(register);
rem2=std(newdata);
if rem2>thresholds*rem1
    flag=1;
end
end

