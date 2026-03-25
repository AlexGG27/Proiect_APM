director_script = fileparts(mfilename('fullpath'));
if isempty(director_script)
    director_script = pwd;
end

% Simulare AGC.
N = 2000;
fd = 100;
fs = 8000;

a = 0.5;
A = [1.5 * a, 0.7 * a, 0.9 * a, 1.2 * a];

% Construieste semnalul de intrare pe patru trepte de amplitudine.
x = zeros(1, N);
for k = 1:4
    for i = 1 + (k - 1) * N / 4 : k * N / 4
        x(i) = A(k);
        % x(i)=A(k)*sin(2*pi*i*fd/fs);
    end
end

% y(n)=g(n-1)*x(n)
% g(n)=g(n-1)+mu[REF-abs(y(n))]
% sau
% g(n)=g(n-1)+mu[REF-(1/N)*SUM{abs(y(n))}]
y = zeros(1, N);

g1 = 0; % g(n-1)
mu = 0.05;

% Referinta de amplitudine.
V = 1;
REF = V * a;

M = 4;
delay = zeros(1, M);
k = 1;

for i = 1:N
    y(i) = g1 * x(i);

    delay(k) = abs(y(i));
    k = k + 1;
    if (k == M + 1)
        k = 1;
    end

    s = 0;
    for j = 1:M
        s = s + delay(j);
    end

    g = g1 + mu * (REF - (1 / M) * s);
    g1 = g;
end

figure(1);
plot(x); hold on;
plot(y); grid; hold off
legend("input", "output");

% Salveaza semnalul de intrare generat pentru simulare.
fis = fopen(fullfile(director_script, 'x_agc.txt'), 'wt');
fprintf(fis, '%1.14f\n', x);
fclose(fis);
