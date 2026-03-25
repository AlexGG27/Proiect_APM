director_script = fileparts(mfilename('fullpath'));
if isempty(director_script)
    director_script = pwd;
end

% Simulare filtru median.
A = 0.99;
fd = 200;
fs = 8000;
K = 1;
W = 2 * K + 1;

xz = load(fullfile(director_script, 'input_imp.dat'));
xz = xz(:).';
N = numel(xz);

x = zeros(1, N);
y = zeros(1, N);
delay = zeros(1, W);
delay_sorted = zeros(1, W);

% Genereaza semnalul util pentru comparatie grafica.
for i = 1:N
    x(i) = A / 2 * (1 + sin(2 * pi * i * fd / fs));
end

% Aplica sortarea prin selectie pe fereastra glisanta.
for i = 1:N
    delay = [xz(i) delay(1:W-1)];
    delay_sorted = delay;
    for k = 1:W
        min = k;
        for j = k:W
            if (delay_sorted(j) <= delay_sorted(min))
                min = j;
            end
        end
        tmp = delay_sorted(k);
        delay_sorted(k) = delay_sorted(min);
        delay_sorted(min) = tmp;
    end

    y(i) = delay_sorted(K + 1);
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
plot(1:N, xz, 'b', 1:N, y, 'r'); grid;

% Salveaza semnalul de intrare impur pentru comparatii ulterioare.
fis = fopen(fullfile(director_script, 'xz_imp.txt'), 'wt');
fprintf(fis, '%1.14f\n', xz);
fclose(fis);
