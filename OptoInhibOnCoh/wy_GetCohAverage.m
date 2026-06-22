function output=wy_GetCohAverage(coherence,passband)
freq=coherence.F;
freq_band=intersect((find(freq>passband(1))),(find(freq<passband(2))));
count=1;
for ch_i=1:20
     for ch_j=21:32         
        eval(['output(count)=mean(coherence.mPFC_rACC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(freq_band));']);
        count=count+1;
    end
end

for ch_i=1:20
     for ch_j=33:48         
        eval(['output(count)=mean(coherence.mPFC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(freq_band));']);
        count=count+1;
    end
end

for ch_i=1:20
     for ch_j=49:64        
        eval(['output(count)=mean(coherence.mPFC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(freq_band));']);
        count=count+1;
    end
end

for ch_i=21:32
     for ch_j=33:48         
        eval(['output(count)=mean(coherence.rACC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(freq_band));']);
        count=count+1;
    end
end

for ch_i=21:32
     for ch_j=49:64         
        eval(['output(count)=mean(coherence.rACC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(freq_band));']);
        count=count+1;
    end
end

for ch_i=33:48
     for ch_j=49:64         
        eval(['output(count)=mean(coherence.PPC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(freq_band));']);
        count=count+1;
    end
end
count=count-1;
output=output';
end