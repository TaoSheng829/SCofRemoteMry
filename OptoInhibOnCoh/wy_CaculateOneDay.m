function [gamma_coherence,theta_coherence]=wy_CaculateOneDay(data_path,filename,cut_params)
%==================================caculate===================================
tic
cutted_data=wy_CutMat(wy_ReadOriginData(data_path,filename),cut_params);
coherence=wy_GetCoherence(cutted_data);
gamma_coherence=wy_GetCohAverage(coherence,[30 90]);
theta_coherence=wy_GetCohAverage(coherence,[4 12]);
printf('one day ready!')
toc