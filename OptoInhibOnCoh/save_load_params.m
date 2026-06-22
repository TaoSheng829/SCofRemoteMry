clear Record
params.passband=[60 90];params.order=3;params.Fs=1000;
if params.passband(1) == 0,
	[params.b,params.a] = cheby2(params.order,20,params.passband(2)/(params.Fs/2),'low');
elseif params.passband(2) == inf
    [params.b,params.a] = cheby2(params.order,20,params.passband(1)/(params.Fs/2),'high');
else
	[params.b,params.a] = cheby2(params.order,20,params.passband/(params.Fs/2));
end

coh_params.tapers=[5 9];
coh_params.pad=0;
coh_params.Fs=1000;
coh_params.fpass=[60 90];
coh_params.err=[0 1];
coh_params.trialave=0;
save('matlab_gamma.mat');