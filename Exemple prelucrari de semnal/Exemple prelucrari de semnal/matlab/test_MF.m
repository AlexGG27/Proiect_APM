% filtru median

N=100;
A=0.99;
p=0.1;

fd=200;
fs=8000;

x=zeros(1,N);
z=zeros(1,N);
xz=zeros(1,N);
y=zeros(1,N);
% y1=zeros(1,N);
K=1;
W=2*K+1;

delay=zeros(1,W);
delay_sorted=zeros(1,W);

% x(n) 
for i=1:N
    x(i)=A/2*(1+sin(2*pi*i*fd/fs));
end

% xz(n)

%xz = 0.99*imnoise(x,"salt & pepper", p);
xz=load('input_imp.dat');
%median

% y1=medfilt1(xz,W);

%
for i=1:N
delay = [xz(i) delay(1:W-1)];
% delay_sort=sort(delay);
% sortare
% sortare prin selectie
delay_sorted=delay;
for k=1:W
min=k;
    for j=k:W
        if (delay_sorted(j)<=delay_sorted(min))
        min=j;
        end
    end
    tmp=delay_sorted(k);
    delay_sorted(k)=delay_sorted(min);
    delay_sorted(min)=tmp;
end

% median value
y(i)=delay_sorted(K+1);
end

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

fis=fopen('xz_imp.txt','wt');
fprintf(fis,'%1.14f\n' ,xz); 
fclose(fis);
