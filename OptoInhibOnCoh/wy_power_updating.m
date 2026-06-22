%%
% %power
% [power]=getPower('190115_2');
% 
% for i=1:16
%     eval(['s=power.FP',num2str(i),';']);
%     G = fspecial('gaussian', [3 3], 2);
%     S= imfilter(s,G,'same');
% 
%     imagesc((S([80:100 200:240],8:25))');
%     set(gca,'YDir','normal');
%     set(gca,'Ytick',[20 40 60 80 100 120],'Yticklabel',{'10','20','30','40','50','60'}) ;
%     colorbar
%     colormap jet
%     xlabel('时间 t/s'); 
%     ylabel('频率 f/Hz');
%     title('No1:freeze');     
%     saveas(gcf,[cd,'\picture\power\power0_90\non_freeze_power',num2str(i),'.jpg'])
% end
% for i=33:48
%     eval(['s=power.FP',num2str(i),';']);
%     G = fspecial('gaussian', [3 3], 2);
%     S= imfilter(s,G,'same');
% 
%     imagesc((S([80:100 200:240],8:25))');
%     set(gca,'YDir','normal');
%     set(gca,'Ytick',[20 40 60 80 100 120],'Yticklabel',{'10','20','30','40','50','60'}) ;
%     colorbar
%     colormap jet
%     xlabel('时间 t/s'); 
%     ylabel('频率 f/Hz');
%     title('No1:freeze');     
%     saveas(gcf,[cd,'\picture\power\power0_90\non_freeze_power',num2str(i),'.jpg'])
% end