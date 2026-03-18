% input signal

A=0.5;

N=1000; % numar de esantioane
D = 128;% intirziere
M = 256; % numar de coeficienti FIR

a=0.05;

fd=100;
fs=8000;

x=zeros(1,N);
z=zeros(1,N);
xz=zeros(1,N);
y=zeros(1,N);

delay=zeros(1,D);
delay_FIR = zeros(1,M);

h=zeros(1,M); % FIR coeff
mu=0.01; % pas adaptare 0.01, 0.1
lambda=0.01; %0.5
e=zeros(1,N);

% z(n)
z=randn(1,N);

% x(n) 
for i=1:N
    x(i)=A*sin(2*pi*i*fd/fs);
    z(i)=a*z(i);
end
% xz(n) 
for i=1:N
    xz(i)=z(i)+x(i);
end

%
xz=load("input_ale.dat");

%
% LMS
for i=1:N
    delay = [xz(i) delay(1:D-1)];
    delay_FIR = [delay(D) delay_FIR(1:M-1)];
    y(i)=0;
    for k=1:M
        y(i)=y(i)+h(k)*delay_FIR(k);
    end
    e(i) = xz(i) - y(i);
    for m = 1:M
        h(m) = (1-mu*lambda)*h(m) + mu * e(i) * delay_FIR(m);
    end
end

% plots

figure(1);

subplot(311);
plot(x); grid;
title('x(n)');
subplot(312);
plot(xz); grid;
title('xz(n)');
subplot(313);
plot(y); grid;
title('y(n)');

figure(2);
plot(1:N,xz,'b',1:N,y,'r'); grid;

%save files

fis=fopen('xz_ale.txt','wt');
fprintf(fis,'%1.14f\n' ,xz); 
fclose(fis);
