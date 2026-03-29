director_script = fileparts(mfilename('fullpath'));
if isempty(director_script)
    director_script = pwd;
end

A = 0.5;
D = 128; % intarziere
M = 256; % numar de coeficienti FIR
a = 0.05;
fd = 100;
fs = 8000;
mu = 0.01; % pas de adaptare
lambda = 0.01;

% Incarca semnalul folosit la simulare din acelasi folder cu scriptul.
xz = load(fullfile(director_script, 'input_ALE.dat'));
xz = xz(:).';
N = numel(xz);

x = zeros(1, N);
z = randn(1, N);
y = zeros(1, N);
e = zeros(1, N);

delay = zeros(1, D);
delay_fir = zeros(1, M);
h = zeros(1, M);

% Reconstruieste semnalul util teoretic pentru reprezentare grafica.
for i = 1:N
    x(i) = A * sin(2 * pi * i * fd / fs);
    z(i) = a * z(i);
end

% Ruleaza adaptarea de tip LLMS pe intrarea incarcata din fisier.
for i = 1:N
    delay = [xz(i) delay(1:D-1)];
    delay_fir = [delay(D) delay_fir(1:M-1)];
    y(i) = 0;
    for k = 1:M
        y(i) = y(i) + h(k) * delay_fir(k);
    end
    e(i) = xz(i) - y(i);
    for m = 1:M
        h(m) = (1 - mu * lambda) * h(m) + mu * e(i) * delay_fir(m);
    end
end

% Afisari grafice.
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
plot(1:N, xz, 'b', 1:N, y, 'r'); grid;

% Salveaza semnalul de intrare folosit in simulare.
fis = fopen(fullfile(director_script, 'xz_ale.txt'), 'wt');
fprintf(fis, '%1.14f\n', xz);
fclose(fis);
