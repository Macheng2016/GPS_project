%main program for the simulation of multi vehicle localization algorithm,
%created by macshen
clear all
close all
N=1; % # of total vehicles 
% load('distance_and_gradient.mat');  %contains grid_size, distance and gradient of distance from road centers
% global dis;
% global grad;   %global quantities to share with sub-function for interpolating distances
% dis=distance;    
% grad=grad_dis;

lane_width=3.5;   %width of a single lane
vehicle_width=1.8;  %use vehicle width to increase the positioning accuracy, it is assumed that the GPS receiver locates at the center of the vehicle
velocity=2.5;  %vehicle velocity
Ns=40;  % #of simulation time points
% Np=500; % #of particles
mpmat=cell(N);   %multipath error time history for N vehicles
for i=1:N
mpmat{i}=mpgen(24,1200,1,floor(10000*rand(1))+54321+i); %generate multipath error, use different random seeds
end
orgllh = [40*pi/180 80*pi/180 0];  %origin of the local coordinate system, first latitude, second longitudinate 
orgxyz = llh2xyz(orgllh);   %convert the origin to the xyz ECEF cooridinate system
loadgps
startt=500; t = startt; deltat=0.1;
%segp = [150 90 .2; 150 90 .2; 150 90 .2];
%usrenu = pathgen([0 0 0],[5 0],segp,deltat);
usrenu{1}(1:Ns,1)=(6:velocity*deltat:6+velocity*deltat*(Ns-1))';
usrenu{1}(1:Ns,2)=50-lane_width/2;
usrenu{1}(1:Ns,3)=0;
% for k=1:3
% usrenu{k}(1:30,1)=(6:velocity:6+velocity*29)';
% usrenu{k}(1:30,2)=50-lane_width/2;
% usrenu{k}(1:30,3)=0;
% end
% for k=4:6
% usrenu{k}(1:30,1)=(93:-velocity:93-velocity*29)';
% usrenu{k}(1:30,2)=50+lane_width/2;
% usrenu{k}(1:30,3)=0;
% end
% for k=7:9
% usrenu{k}(1:30,2)=(6:velocity:6+velocity*29)';
% usrenu{k}(1:30,1)=50+lane_width/2;
% usrenu{k}(1:30,3)=0;
% end
% for k=10:12
% usrenu{k}(1:30,2)=(93:-velocity:93-velocity*29)';
% usrenu{k}(1:30,1)=50-lane_width/2;
% usrenu{k}(1:30,3)=0;             %generate the vehicles' path in the local coordinate system
% end
%EndLoop = max(size(usrenu));
%bar1 = waitbar(0,'Generating User Solutions...  ');
%id=[]; %added by macshen
%pr_err=[]; %added by macshen
state_mean=[6;50-lane_width/2;velocity;0];
state_cov=eye(4,4);    %initialize state vector and its covariance matrix for the Kalman filter
for i = 1:Ns  %draw the first step
    t = t + deltat;
%     pf=zeros(Np,3); %first two colomns are coordinates, 3rd colomn is weight,
%     %here particles represents the offset vector that correct the vehicles' pose, therefore the particles are common to each vehicle
%     %particles are initilized every time step
%     pf(:,3)=1/Np;   %initialize weight
%     pf(:,1:2)=randn(Np,2)*3;   %try Gaussian sampling, this should be modified later
    noise_scaling_factor=[1 0 0 0 0];
    figure(1);
    clf;
    plotcov2d(usrenu{1}(i,1),usrenu{1}(i,2),[1,0;0,1],'r',0,0,0,1);  %plot the true position of vehicle as a circle
    axis([0,30,35,65]);
    axis equal;
    hold on
     
    
    for k=1:N   %GPS measurement loop for all the vehicles
    usrxyz{k}=enu2xyz(usrenu{k}(i,:),orgxyz);
    [svxyzmat{k},svid{k}] = gensv(usrxyz{k},t,5);   % here 5 is the mask angle to determine which satellites are visible to the vehicles, macshen
   % id=[id;svid(1)];  %added by macshen
    [prvec{k},adrvec{k},pr_err_vec{k}] = genrng(k,usrxyz{k},svxyzmat{k},svid{k},t,noise_scaling_factor,[],mpmat{k});  %pr_err_vec added by macshen, receiver identification k seems to be redundant here. the magnitude of noise flag is thermal,Tropospheric,SA,Multipath,Ionospheric
   % pr_err=[pr_err;pr_err_vec(1)]; %added by macshen
    [estusr{k},H{k}] = olspos(prvec{k},svxyzmat{k});  %sovle for the vehicle pose given pr measurement, macshen
    
    estenu{k}(i,:) = ( xyz2enu(estusr{k}(1:3),orgxyz) )';   %transform the ECEF coordinate to local one with origin orgxyz
    err{k}(i,1:3) = estenu{k}(i,1:3) - usrenu{k}(i,:);
    terr{k}(i) = estusr{k}(4);  % true clk bias is zero
    

    end   %end for loop of vehicle #
    
    plotcov2d(estenu{1}(i,1),estenu{1}(i,2),[1,0;0,1],'b',0,0,0,1);  %plot the GPS estimated position of vehicle as a circle
%     plotSamples([pf(:,1)+estenu{1}(i,1),pf(:,2)+estenu{1}(i,2)],'b');  %plot the hypothetical position of 1st vehicle before particle filter
    
    for k=1:N  %pf loop for each vehicle
        sigma_multipath2=1.67*noise_scaling_factor(4)^2;   %variance of mutlipath,calculated from the multipath noise in the simulation
        sigma_thermal2=1.0*noise_scaling_factor(1)^2;
        sigma_eta2=sigma_multipath2+sigma_thermal2;
        sigma_x=deltat^4*0.5^2;  %unmodeled position noise caused by acceleration,assuming the variance of acceleration is 1.
        sigma_x_dot=deltat^2;  %unmodeled velocity noise caused by acceleration;
        
%         sigma_map2=0.01;  %variance of map inprecision, this might be larger for real map
        P=inv(H{k}.'*H{k})*sigma_eta2;  %whole position covariance caused by non-common noise
        P=P(1:2,1:2);  %extract the sub covariance matrix of x,y position
         
        %beginning of Kalman filter for position estimation
        %prediction step
        if i>=2  %first step does not need prediction
        [state_mean,state_cov]=Kalman_prediction(state_mean,state_cov,sigma_x,sigma_x_dot,deltat);
        end
        %update step
        [state_mean,state_cov]=Kalman_update(state_mean,state_cov,estenu{k}(i,1:2)',P);
        
%         pf(:,1:2)=pf(:,1:2)+0.2*randn(Np,2);  %This line adds some random noise to the particles to increase diversity
%         %while it should be noted that this would cause a wrong posterior
%         for j=1:Np %loop for particles' weights
%             pf(j,3)=cal_weight(pf(j,1:3),estenu{k}(i,1:2),P,sigma_map2,lane_width,vehicle_width,grid_size); %the last argument allow noise to be added to the particles
%         end
%         pf=resample(pf);  %resample, %weight needn't be normalized. After resample, weight has been normalized
    end   %end (for k=1:N)
    
%     [mu,cov]=pf_to_Gaussian(pf);  %transform particle filter to Gaussian
%     deter(i)=det(cov);  %calculate the determinant of the covariance matrix
    
%     err_temp=[];
%     for k=1:N
%     err_temp=[err_temp;err{k}(i,1:2)];   %extract the error vector for each vehicle
%     end
%     deter_error(i)=cal_deter_error(err_temp);  %calculate the determinant of the covariance of error
    
    %calculate the determinant of the variance of the true error, this is expected to be related with the estimation covariance
%     plotSamples([pf(:,1)+estenu{1}(i,1),pf(:,2)+estenu{1}(i,2)],'r');  %plot the estimated position sample of 1st vehicle
    plotcov2d(state_mean(1),state_mean(2),state_cov(1:2,1:2),'g',0,0,0,3);  %plot position estimated by Kalman filter
    pause(1);
    hold off
 	% waitbar(i/EndLoop)   
end  %end (for i = 1:Ns)
%close(bar1);
% x=100*rand(1000,1);
% y=100*rand(1000,1);
% for k=1:1000
% d(k)=Distance_to_road([x(k),y(k)],grid_size);    %pay attention to changing the grid-size if 
% end