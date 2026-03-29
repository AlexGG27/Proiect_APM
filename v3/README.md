# v3

Folderul `v3` contine varianta completa revizuita dupa analiza documentatiilor:

- `c:\Users\alexg\Downloads\05-1.pdf`
- `c:\Users\alexg\Downloads\15-1.pdf`

## Fisiere importante

- `test_P2_STM32_2026/test/Core/Src/main.c`
- `DSP test/DSP test/test_ext/test_ext.asm`
- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/matlab/test_AGC.m`
- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/matlab/test_ALE.m`
- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/matlab/test_MF.m`
- `ANALIZA_MODIFICARI.md`
- `documentatie/RAPORT_V3.md`
- `documentatie/DIAGRAME_V3.md`
- `documentatie/surse_pdf`

## Ideea pe scurt

- Pe STM32 am corectat latching-ul comenzii la apasarea lui `PRG`.
- In plus, comanda trimisa spre DSP este construita cu `D7` si `D6` pe `1`, conform documentatiilor noi.
- Scripturile MATLAB au fost facute mai robuste la rulare din orice director.
- Pe DSP am pastrat implementarea integrata existenta, pentru ca documentatia noua nu ofera o varianta mai buna si consistenta pentru partea de executie.
- In `v3` exista acum si infrastructura proiectelor copiata din sursele originale, ca sa poti deschide mai usor proiectele in IDE.
- In `v3/documentatie` exista acum un raport complet si diagrame dedicate pentru aceasta varianta.
