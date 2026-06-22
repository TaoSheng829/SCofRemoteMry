function [comod] = bz_ModIndexCF(lfpphs,lfpamp,phaserange,amprange,flagPlot)
%%

nfreqs = length(amprange);

%% Filter LFP for phase
parfor bnd = 1:length(phaserange)-1
    filtered_phase(bnd,:) = bz_Filter(lfpphs,'passband',phaserange(bnd:bnd+1),'filter','fir1');
end

%% Wavelet Transform LFP in intervals
comod = zeros(length(amprange)-1,length(filtered_phase));
for apr = 1:length(amprange)-1
    wavespec_amp = bz_WaveSpec(lfpamp,'frange',[amprange(apr) amprange(apr+1)],'nfreqs',1);
    
    wavespec_amp.data = abs(wavespec_amp.data);
    %% Bin phase and power
    numbins = 50;
    phasebins = linspace(-pi,pi,numbins+1);
    phasecenters = phasebins(1:end-1)+(phasebins(2)-phasebins(1));
    
    for idx = 1:length(filtered_phase)
        [phasedist,~,phaseall] = histcounts(filtered_phase(idx).phase,phasebins);
        
        phaseAmp = zeros(numbins,1);
        for bb = 1:numbins
            phaseAmp(bb) = mean(wavespec_amp.data(phaseall==bb),1);
        end
        
        phaseAmp = phaseAmp./sum(phaseAmp,1);
        comod(apr,idx) = sum(phaseAmp.*log(phaseAmp./(ones(numbins,size(phaseAmp,2))/numbins)))/log(numbins);
    end
    
end

ampfreqs = wavespec_amp.freqs;
%% Plot
if flagPlot
    figure
    imagesc(phaserange,log2(ampfreqs),comod);
    colormap jet
    hold on
    xlabel('Frequency phase');
    ylabel('Frequency amplitude')
    %LogScale('y',2)
    colorbar
    axis xy
    
end

