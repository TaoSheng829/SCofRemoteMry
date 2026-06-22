function coherence=wy_GetCoherence(cutted_data)

params.tapers=[5 9];
params.pad=0;
params.Fs=1000;
params.fpass=[0 140];
params.err=[0 1];
params.trialave=0;
     
[~,~,~,~,~,coherence.F]=coherencyc(cutted_data.FP01,cutted_data.FP02,params);

for ch_i=1:20
     for ch_j=21:32 
        %截取指定通道数，指定时间的数据，并计算相关性。t:Theta,b:Beta,g:Gamma
        FA='FA';eval([FA,'=cutted_data.FP',num2str(ch_i,'%02d'),';']);
        FB='FB';eval([FB,'=cutted_data.FP',num2str(ch_j,'%02d'),';']); 
        [C,~,~,~,~,~]=coherencyc(FA,FB,params);
        c=smooth(C.*C,500);   
        eval(['coherence.mPFC_rACC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'=c;']);
        clear c C FA FB;        
    end
end
printf('one coherence ready!');

for ch_i=1:20
     for ch_j=33:48 
        %截取指定通道数，指定时间的数据，并计算相关性。t:Theta,b:Beta,g:Gamma
        FA='FA';eval([FA,'=cutted_data.FP',num2str(ch_i,'%02d'),';']);
        FB='FB';eval([FB,'=cutted_data.FP',num2str(ch_j,'%02d'),';']); 
        [C,~,~,~,~,~]=coherencyc(FA,FB,params);
        c=smooth(C.*C,500);   
        eval(['coherence.mPFC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'=c;']);
        clear c C FA FB;        
    end
end
printf('one coherence ready!');

for ch_i=1:20
     for ch_j=49:64 
        %截取指定通道数，指定时间的数据，并计算相关性。t:Theta,b:Beta,g:Gamma
        FA='FA';eval([FA,'=cutted_data.FP',num2str(ch_i,'%02d'),';']);
        FB='FB';eval([FB,'=cutted_data.FP',num2str(ch_j,'%02d'),';']); 
        [C,~,~,~,~,~]=coherencyc(FA,FB,params);
        c=smooth(C.*C,500);   
        eval(['coherence.mPFC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'=c;']);
        clear c C FA FB;        
    end
end
printf('one coherence ready!');
for ch_i=21:32
     for ch_j=33:48 
        %截取指定通道数，指定时间的数据，并计算相关性。t:Theta,b:Beta,g:Gamma
        FA='FA';eval([FA,'=cutted_data.FP',num2str(ch_i,'%02d'),';']);
        FB='FB';eval([FB,'=cutted_data.FP',num2str(ch_j,'%02d'),';']); 
        [C,~,~,~,~,~]=coherencyc(FA,FB,params);
        c=smooth(C.*C,500);   
        eval(['coherence.rACC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'=c;']);
        clear c C FA FB;        
    end
end
printf('one coherence ready!');

for ch_i=21:33
     for ch_j=49:64 
        %截取指定通道数，指定时间的数据，并计算相关性。t:Theta,b:Beta,g:Gamma
        FA='FA';eval([FA,'=cutted_data.FP',num2str(ch_i,'%02d'),';']);
        FB='FB';eval([FB,'=cutted_data.FP',num2str(ch_j,'%02d'),';']); 
        [C,~,~,~,~,~]=coherencyc(FA,FB,params);
        c=smooth(C.*C,500);   
        eval(['coherence.rACC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'=c;']);
        clear c C FA FB;        
    end
end
printf('one coherence ready!');
for ch_i=33:48
     for ch_j=49:64 
        %截取指定通道数，指定时间的数据，并计算相关性。t:Theta,b:Beta,g:Gamma
        FA='FA';eval([FA,'=cutted_data.FP',num2str(ch_i,'%02d'),';']);
        FB='FB';eval([FB,'=cutted_data.FP',num2str(ch_j,'%02d'),';']); 
        [C,~,~,~,~,~]=coherencyc(FA,FB,params);
        c=smooth(C.*C,500);   
        eval(['coherence.PPC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'=c;']);
        clear c C FA FB;        
    end
end
printf('one coherence ready!');
end

