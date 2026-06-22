function cutted_data=wy_CutMat(origin_data,cut_params) %#ok<*INUSL,*STOUT>

for ch_i=1:64
    eval(['cutted_data.FP',num2str(ch_i,'%02d'),'=origin_data.FP',num2str(ch_i,'%02d'),'(',num2str(cut_params(2)),':',num2str(cut_params(3)),');']);
end

end