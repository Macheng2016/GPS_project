function main_evaluation(flag)

%calculate and plot the figures in 
%[1] Shen, Macheng, Ding Zhao, and Jing Sun. "The Impact of Road Configuration in V2V-based Cooperative Localization: Mathematical Analysis and Real-world Evaluation." arXiv preprint arXiv:1705.00568 (2017).
%flag=1, plot Fig. 3;   those plot might seem different from those in the
%paper, mainly due to the randomness of the empirical expectation calculated by MC method,in the paper
%each expected value is calculated with 10000 samples and 5000 particles,
%while this program only uses 100 samples and 1000 particles for efficiency
%flag=2, plot Fig. 4;
%flag=3, plot Fig. 5;
%flag=4, plot Fig. 6;
%flag=5, load Fig. 7 and Fig. 8;
%flag=6, evaluation the CMM error in Ann Arbor (Fig. 9-Fig. 11) 


if flag==1
        n=3:12;
        E_X=pi^2*0.09/12./log(n);
        [n_MC,E_MC]=MC_analytic(0.3);
        
        figure
        hold on;
        plot(n*4,E_X,'b','LineWidth',1.5)
        plot(n_MC,E_MC,'y','LineWidth',1.5)
        legend('Asymptotic formula','Simulation using Eq. (12)')
        ylabel('Mean square error (m^2)')
        title('Fig. 3')
end

if flag==2
    n=10:50;
    E_X=8/9./n+1.5*0.09./n;
    
    [n_MC,E_MC]=mean_err_MC_uniform(0.09);
    
        figure
        hold on;
        plot(n,E_X,'b','LineWidth',1.5)
        plot(n_MC,E_MC,'y','LineWidth',1.5)
        legend('Asymptotic formula','Monte Carlo Simulation')
        ylabel('Mean square error (m^2)')
        title('Fig. 4')
end

if flag==3
    [n_ort,E_ort]=MC_analytic(1);
    [n_uni,E_uni]=mean_err_MC_uniform(1);
    figure
        hold on;
        loglog(n_ort,E_ort,'b','LineWidth',1.5)
        loglog(n_MC,E_MC,'r','LineWidth',1.5)
        legend('Orthogonal road','Uniformly distributed random road')
        ylabel('Mean square estimation error (m^2)')
        title('Fig. 5')
end

if flag==4
    figure
    hold on;
    for k=10:2:20
        m=0;
        for i=1:10000
            angle=rand(1,k)*2*pi;
            temp=square_error(angle,2,0.5,0);
            if temp<5 
            er(m+1)=temp;
            m=m+1;
            end
        end
        histogram(er);
    end
    xlabel('Mean square estimation error (m^2)')
    ylabel('Frequency')
    title('Fig. 6')
    legend('Number of vehicles=10','Number of vehicles=12','Number of vehicles=14','Number of vehicles=16','Number of vehicles=18','Number of vehicles=20')
end

if flag==5
    openfig('number of vehicle distribution.fig');
    figure
    A = imread('vehicle_density_two_day.png');
    image(A)
end

if flag==6
    CMM_evaluation(1);   %1-12 o'clock
    CMM_evaluation(2);   %13-24 o'clock
    CMM_evaluation(3);   %Monday-Sunday
    CMM_evaluation(4);   %January-December
end

end
    
    
