function [theta beta gamma]=wy_ChooseTime(origin_data,channelA,channelB)

params.tapers=[5 9];
params.pad=0;
params.Fs=1000;
params.fpass=[0 140];
params.err=[0 1];
params.trialave=0;
%[~,~,~,~,~,F]=coherencyc(origin_data.FP01(1:60000),origin_data.FP02(1:60000),params);
tic
bin=1;
    for i=1:60000:((length(origin_data.FP01))-60000)
        count=1;
        for j=channelA
            for k=channelB
                eval(['[C,~,~,~,~,~]=coherencyc(origin_data.FP',num2str(j,'%02d'),'(i:(i+59999)),origin_data.FP',num2str(k,'%02d'),'(i:(i+59999)),params);']);
                theta(bin,count)=mean((C(264:787)).*(C(264:787))); 
                beta(bin,count)=mean((C(788:1967)).*(C(788:1967)));
                gamma(bin,count)=mean((C(1968:5899)).*(C(1968:5899))); 
                clear C
                count=count+1;
            end
        end
        bin=bin+1;
    end
clear bin
toc

%=====================================ª≠≥ˆ»»µ„Õº========================================
 