function main_CMM(flag,mp_flag)
%this program calls the three CMM methods and draws corresponding plot 
%depending on the input flag:

%flag=1, call RBPF;
%flag=2, call smoothed static method;
%flag=3, call static method;
%flag=4, plot Fig. 5 and Fig. 6     %note that those plots will not look
%exatly as those in the paper due to the intrisic randomness of the
%algorithm
%flag=5, plot Fig. 7
%flag=6, plot Fig. 8
%flag=7, load other plots



%mp_flag=1, simulate multipath error, only active when flag=1|2|3;
%otherwise, ignored

if flag==1
    cmm_rbpf(mp_flag);
end
if flag==2
    cmm_smoothed_static(mp_flag);
end
if flag==3
    cmm_static(mp_flag);
end
if flag==4
    [er_rbpf,det_rbpf]=cmm_rbpf(0);
    [er_sm,det_sm]=cmm_smoothed_static(0);
    [er_sta,det_sta]=cmm_static(0);
    figure
    hold on;
    plot(1:length(er_sta),er_sta,'b','LineWidth',1.5)
    plot(1:length(er_sm),er_sm,'r','LineWidth',1.5)
    plot(1:length(er_rbpf),er_rbpf,'g','LineWidth',1.5)
    legend('Static method','Smoothed static method','RBPF')
    ylabel('Localization error (m)')
    title('Fig. 5')
    
    figure
    hold on;
    semilogy(1:length(det_sta),det_sta,'b','LineWidth',1.5)
    semilogy(1:length(det_sm),det_sm,'r','LineWidth',1.5)
    semilogy(1:length(det_rbpf),det_rbpf,'g','LineWidth',1.5)
    legend('Static method','Smoothed static method','RBPF')
    ylabel('Determinant of covariance (m^2)')
    title('Fig. 6')
end
if flag==5
    [er_rbpf,det_rbpf]=cmm_rbpf(1);
    [er_sm,det_sm]=cmm_smoothed_static(1);
    figure
    hold on;
    plot(1:length(er_sm),er_sm,'r','LineWidth',1.5)
    plot(1:length(er_rbpf),er_rbpf,'g','LineWidth',1.5)
    ylabel('Localization error (m)')
    title('Fig. 7')
end
if flag==6
    [er_rbpf,det_rbpf,com_er_rbpf,com_std_rbpf]=cmm_rbpf(0);
    [er_sm,det_sm,com_er_sm,com_std_sm]=cmm_smoothed_static(0);
    figure
    errorbar(com_er_sm,3*com_std_sm,'LineWidth',1.5)
    Legend('Smoothed static method')
    ylabel('Common bias estimation error (m)')
    title('Fig. 8 (left)')
    
    figure
    errorbar(com_er_rbpf,3*com_std_rbpf,'LineWidth',1.5)
    Legend('RBPF')
    ylabel('Common bias estimation error (m)')
    title('Fig. 8 (right)')
end
if flag==7
    openfig('complexity_error.fig');
    openfig('histogram.fig');
    openfig('position_5sv.fig');
    openfig('position_ego_rohani_RBPF.fig');
end
    


    
