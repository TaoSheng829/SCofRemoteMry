function [coh_gpu] =GPUkernel_coherencyc(channel_data_gpu)
coh_params.tapers=[5 9];
coh_params.pad=0;
coh_params.Fs=1000;
coh_params.fpass=[30 90];
coh_params.err=[0 1];
coh_params.trialave=0;
[coh_gpu,~,~,~,~,~]=coherencyc(channel_data_gpu(1:1000),channel_data_gpu(1001:2000),coh_params); 
end

