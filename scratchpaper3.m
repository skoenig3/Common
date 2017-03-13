%% Test: ICA can only separate linearly mixed sources
clc; clf; clear all; close all;

opt = 1; % Linear: 1; Nonlinear: 2; Linear Noisy: 3; Nonlinear Noisy: 4;

%% Create two signals
A = sin(linspace(0,50, 1000)); % A
B = cos(linspace(0,37, 1000)+5); % B
C = sin(linspace(0,20, 1000)+10); % C

%% Mixture of linear signals
if opt == 1
    M1 = A-2*B+C; % mixing 1
    M2 = 1.73*A+3.41*B-9.2*C; % mixing 2
    M3 = 0.2*A+0.41*B-0.5*C; % mixing 3
    
%% Mixture of nonlinear signals
elseif opt == 2
    M1 = A-2*B+C; % mixing 1
    M2 = 1.73*A+3.41*B.^2-9.2*C; % mixing 2 B.^1.1
    M3 = 0.2*A+0.41*B-0.5*C; % mixing 3 1000*C
    
%% Mixture of linear signals with white Gaussian noise
elseif opt == 3
    M1 = A-2*B+C+(0.2+0.1.*randn(1000,1))'; % mixing 1
    M2 = 1.73*A+3.41*B-9.2*C+(0.1+0.05.*randn(1000,1))'; % mixing 2
    M3 = 0.2*A+0.41*B-0.5*C-(0.01+0.1.*randn(1000,1))'; % mixing 3

%% Mixture of nonlinear signals with white Gaussian noise
elseif opt == 4
    M1 = A-2*B+C+(0.2+0.1.*randn(1000,1))'; % mixing 1
    M2 = 1.73*A+3.41*B.^2-9.2*C+(0.1+0.05.*randn(1000,1))'; % mixing 2 B.^1.1
    M3 = 0.2*A+0.41*B-0.5*C-(0.01+0.1.*randn(1000,1))'; % mixing 3 1000*C
    
end

%% Run fast ICA 4 times
ICs = zeros(12,1000);
for i = 1:4
    % compute unminxing using fastICA
    ICs((1+3*(i-1)):(1+3*(i-1))+2,:) = fastica([M1;M2;M3]);
end

%% Plot
figure,
subplot(3,6,1), plot(A, 'r'); % plot A
subplot(3,6,7), plot(B, 'r'); % plot B
subplot(3,6,13), plot(C, 'r'); % plot C

subplot(3,6,2), plot(M1, 'g'); % plot mixing 1
subplot(3,6,8), plot(M2, 'g'); % plot mixing 2
subplot(3,6,14), plot(M3, 'g'); % plot mixing 3

subplot(3,6,3), plot(ICs(1,:), 'r'); % plot IC 1
subplot(3,6,9), plot(ICs(2,:), 'r'); % plot IC 2
subplot(3,6,15), plot(ICs(3,:), 'r'); % plot IC 3

subplot(3,6,4), plot(ICs(4,:), 'r'); % plot IC 1
subplot(3,6,10), plot(ICs(5,:), 'r'); % plot IC 2
subplot(3,6,16), plot(ICs(6,:), 'r'); % plot IC 3

subplot(3,6,5), plot(ICs(7,:), 'r'); % plot IC 1
subplot(3,6,11), plot(ICs(8,:), 'r'); % plot IC 2
subplot(3,6,17), plot(ICs(9,:), 'r'); % plot IC 3

subplot(3,6,6), plot(ICs(10,:), 'r'); % plot IC 1
subplot(3,6,12), plot(ICs(11,:), 'r'); % plot IC 2
subplot(3,6,18), plot(ICs(12,:), 'r'); % plot IC 3