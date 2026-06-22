%This code is used for saving matlab.mat imported from main_thetaCL
%===========================================================================================
save_path='D:\wy\20200509_pre_closedloop\data';
filename='E241111_241122pre.pl2';
%===========================================================================================
file_locat = [save_path,'\',filename];
for channel=1:64 % 取决于电极规格
    eval(['tempFP = PL2Ad(file_locat, ''FP',num2str(channel,'%02d'),''');']);
    if ~isempty(tempFP.Values)
        eval(['FP.FP',num2str(channel,'%02d'),' = tempFP.Values;']);
    end
end

movingwin=[1 1];
params.tapers=[5 9];
params.pad=0;
params.Fs=1000;
params.fpass=[0 140];
params.err=[0 1];
params.trialave=0;
k=1;Tos = [];
for ch_i=1:20 % ch_i=1
  for ch_j=[21:32 49:64] % ch_j = 50
    eval(['FA=FP.FP',num2str(ch_i,'%02d'),';']); 
    eval(['FB=FP.FP',num2str(ch_j,'%02d'),';']); 
    [C,~,~,~,~,t,f]=cohgramc(FA,FB,movingwin,params); 
    c=(C.*C); 
%   c(:,:,2)=[];
    clear C
    Tos(:,k)=mean(c(:,5:13),2);
    k=k+1;
  end
end

Tos_mean=mean(Tos);Tos_std=std(Tos);Tos_th=mean(Tos_mean)+2.*mean(Tos_std);
save('Tos_th.mat','Tos_th');

