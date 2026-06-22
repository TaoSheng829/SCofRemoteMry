function origin_data=wy_ReadOriginData(data_path,filename)

origin_data=load([data_path,'\',filename,'.mat']); %#ok<*LOAD>

end
