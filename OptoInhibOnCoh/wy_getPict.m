function wy_getPict( triggle_0724,data28_0724 ) %#ok<*INUSD>
for ch_i=1:20
    for ch_j=21:32 
        %截取指定通道数，指定时间的数据，并计算相关性。t:Theta,b:Beta,g:Gamma
        theta1='theta1';eval([theta1,'=data28_0724.mPFC_rACC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta2='theta2';eval([theta2,'=triggle_0724.mPFC_rACC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta=[theta1;theta2];
        subplot(3,1,1);plot(theta); title('theta');set(gca,'XLim',[0 length(theta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(theta) 0.5*length(theta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(theta1) 1.5*length(theta1)],'Xticklabel',{'前','后'}) ;
        
        beta1='beta1';eval([beta1,'=data28_0724.mPFC_rACC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta2='beta2';eval([beta2,'=triggle_0724.mPFC_rACC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta=[beta1;beta2];
        subplot(3,1,2);plot(beta); title('beta');set(gca,'XLim',[0 length(beta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(beta) 0.5*length(beta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(beta1) 1.5*length(beta1)],'Xticklabel',{'前','后'}) ;
        
        gamma1='gamma1';eval([gamma1,'=mean(data28_0724.mPFC_rACC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma2='gamma2';eval([gamma2,'=mean(triggle_0724.mPFC_rACC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma=[gamma1;gamma2];
        subplot(3,1,3);plot(gamma); title('gamma');set(gca,'XLim',[0 length(gamma)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(gamma) 0.5*length(gamma)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(gamma1) 1.5*length(gamma1)],'Xticklabel',{'前','后'}) ;
        
        saveas(gcf,[cd,'\picture\mPFC_rACC\coh',num2str(ch_i),'&',num2str(ch_j),'.jpg']);
        close all
    end
end
%%
for ch_i=1:20
    for ch_j=33:48 
        %截取指定通道数，指定时间的数据，并计算相关性。t:Theta,b:Beta,g:Gamma
        theta1='theta1';eval([theta1,'=data28_0724.mPFC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta2='theta2';eval([theta2,'=triggle_0724.mPFC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta=[theta1;theta2];
        subplot(3,1,1);plot(theta); title('theta');set(gca,'XLim',[0 length(theta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(theta) 0.5*length(theta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(theta1) 1.5*length(theta1)],'Xticklabel',{'前','后'}) ;
        
        beta1='beta1';eval([beta1,'=data28_0724.mPFC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta2='beta2';eval([beta2,'=triggle_0724.mPFC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta=[beta1;beta2];
        subplot(3,1,2);plot(beta); title('beta');set(gca,'XLim',[0 length(beta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(beta) 0.5*length(beta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(beta1) 1.5*length(beta1)],'Xticklabel',{'前','后'}) ;
        
        gamma1='gamma1';eval([gamma1,'=mean(data28_0724.mPFC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma2='gamma2';eval([gamma2,'=mean(triggle_0724.mPFC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma=[gamma1;gamma2];
        subplot(3,1,3);plot(gamma); title('gamma');set(gca,'XLim',[0 length(gamma)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(gamma) 0.5*length(gamma)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(gamma1) 1.5*length(gamma1)],'Xticklabel',{'前','后'}) ;
        
        saveas(gcf,[cd,'\picture\mPFC_CA1\coh',num2str(ch_i),'&',num2str(ch_j),'.jpg'])
        close all
    end
end


%%
for ch_i=1:20
    for ch_j=49:64
        %截取指定通道数，指定时间的数据，并计算相关性。t:Theta,b:Beta,g:Gamma
        theta1='theta1';eval([theta1,'=data28_0724.mPFC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta2='theta2';eval([theta2,'=triggle_0724.mPFC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta=[theta1;theta2];
        subplot(3,1,1);plot(theta); title('theta');set(gca,'XLim',[0 length(theta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(theta) 0.5*length(theta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(theta1) 1.5*length(theta1)],'Xticklabel',{'前','后'}) ;
        
        beta1='beta1';eval([beta1,'=data28_0724.mPFC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta2='beta2';eval([beta2,'=triggle_0724.mPFC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta=[beta1;beta2];
        subplot(3,1,2);plot(beta); title('beta');set(gca,'XLim',[0 length(beta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(beta) 0.5*length(beta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(beta1) 1.5*length(beta1)],'Xticklabel',{'前','后'}) ;
        
        gamma1='gamma1';eval([gamma1,'=mean(data28_0724.mPFC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma2='gamma2';eval([gamma2,'=mean(triggle_0724.mPFC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma=[gamma1;gamma2];
        subplot(3,1,3);plot(gamma); title('gamma');set(gca,'XLim',[0 length(gamma)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(gamma) 0.5*length(gamma)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(gamma1) 1.5*length(gamma1)],'Xticklabel',{'前','后'}) ;
        
        saveas(gcf,[cd,'\picture\mPFC_PPC\coh',num2str(ch_i),'&',num2str(ch_j),'.jpg'])
        close all
    end
end
%%
for ch_i=21:32
    for ch_j=33:48
        theta1='theta1';eval([theta1,'=data28_0724.rACC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta2='theta2';eval([theta2,'=triggle_0724.rACC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta=[theta1;theta2];
        subplot(3,1,1);plot(theta); title('theta');set(gca,'XLim',[0 length(theta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(theta) 0.5*length(theta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(theta1) 1.5*length(theta1)],'Xticklabel',{'前','后'}) ;
        
        beta1='beta1';eval([beta1,'=data28_0724.rACC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta2='beta2';eval([beta2,'=triggle_0724.rACC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta=[beta1;beta2];
        subplot(3,1,2);plot(beta); title('beta');set(gca,'XLim',[0 length(beta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(beta) 0.5*length(beta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(beta1) 1.5*length(beta1)],'Xticklabel',{'前','后'}) ;
        
        gamma1='gamma1';eval([gamma1,'=mean(data28_0724.rACC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma2='gamma2';eval([gamma2,'=mean(triggle_0724.rACC_CA1.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma=[gamma1;gamma2];
        subplot(3,1,3);plot(gamma); title('gamma');set(gca,'XLim',[0 length(gamma)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(gamma) 0.5*length(gamma)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(gamma1) 1.5*length(gamma1)],'Xticklabel',{'前','后'}) ;
        
        saveas(gcf,[cd,'\picture\rACC_CA1\coh',num2str(ch_i),'&',num2str(ch_j),'.jpg'])
        close all
    end
end
%%
for ch_i=21:32
    for ch_j=49:64
        theta1='theta1';eval([theta1,'=data28_0724.rACC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta2='theta2';eval([theta2,'=triggle_0724.rACC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta=[theta1;theta2];
        subplot(3,1,1);plot(theta); title('theta');set(gca,'XLim',[0 length(theta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(theta) 0.5*length(theta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(theta1) 1.5*length(theta1)],'Xticklabel',{'前','后'}) ;
        
        beta1='beta1';eval([beta1,'=data28_0724.rACC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta2='beta2';eval([beta2,'=triggle_0724.rACC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta=[beta1;beta2];
        subplot(3,1,2);plot(beta); title('beta');set(gca,'XLim',[0 length(beta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(beta) 0.5*length(beta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(beta1) 1.5*length(beta1)],'Xticklabel',{'前','后'}) ;
        
        gamma1='gamma1';eval([gamma1,'=mean(data28_0724.rACC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma2='gamma2';eval([gamma2,'=mean(triggle_0724.rACC_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma=[gamma1;gamma2];
        subplot(3,1,3);plot(gamma); title('gamma');set(gca,'XLim',[0 length(gamma)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(gamma) 0.5*length(gamma)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(gamma1) 1.5*length(gamma1)],'Xticklabel',{'前','后'}) ;
        
        saveas(gcf,[cd,'\picture\rACC_PPC\coh',num2str(ch_i),'&',num2str(ch_j),'.jpg'])
        close all
    end
end
%%
for ch_i=33:48
    for ch_j=49:64
        theta1='theta1';eval([theta1,'=data28_0724.CA1_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta2='theta2';eval([theta2,'=triggle_0724.CA1_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,2);']);
        theta=[theta1;theta2];
        subplot(3,1,1);plot(theta); title('theta');set(gca,'XLim',[0 length(theta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(theta) 0.5*length(theta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(theta1) 1.5*length(theta1)],'Xticklabel',{'前','后'}) ;
        
        beta1='beta1';eval([beta1,'=data28_0724.CA1_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta2='beta2';eval([beta2,'=triggle_0724.CA1_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,3);']);
        beta=[beta1;beta2];
        subplot(3,1,2);plot(beta); title('beta');set(gca,'XLim',[0 length(beta)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(beta) 0.5*length(beta)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(beta1) 1.5*length(beta1)],'Xticklabel',{'前','后'}) ;
        
        gamma1='gamma1';eval([gamma1,'=mean(data28_0724.CA1_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma2='gamma2';eval([gamma2,'=mean(triggle_0724.CA1_PPC.c',num2str(ch_i,'%02d'),'c',num2str(ch_j,'%02d'),'(:,4:6),2);']);
        gamma=[gamma1;gamma2];
        subplot(3,1,3);plot(gamma); title('gamma');set(gca,'XLim',[0 length(gamma)]);set(gca,'YLim',[0 1]);%轴的数据显示范围
        hold on 
        plot([0.5*length(gamma) 0.5*length(gamma)],[0 1],'k');
        xlabel('triggle');
        ylabel('Coherence');
        set(gca,'Xtick',[0.5*length(gamma1) 1.5*length(gamma1)],'Xticklabel',{'前','后'}) ;
        
        saveas(gcf,[cd,'\picture\CA1_PPC\coh',num2str(ch_i),'&',num2str(ch_j),'.jpg'])   
        close all
    end
end





end

