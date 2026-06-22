function [power] =wy_getPower(file)


load([file,'.mat']);
movingwin=[2 1];
params.tapers=[5 9];
params.pad=0;
params.Fs=1000;
params.fpass=[0 90];
params.err=[1 0];
params.trialave=0;

for ch_i=1:64
    data='data';eval([data,'=FP',num2str(ch_i,'%02d'),';']);
    [S,t,f,~]=mtspecgramc(data,movingwin,params);
    eval(['power.FP',num2str(ch_i),'(:,:)=S(110:170,:);']);
end