# Exemple VisualDSP

Acest fisier explica rolul proiectelor din:

`Exemple prelucrari de semnal/Exemple prelucrari de semnal/Visual DSP`

## Verdict scurt

Toate cele 3 exemple sunt complete ca proiecte de test standalone:

- `test_AGC`
- `test_ALE`
- `test_MF`

Toate se build-uiesc local si produc `.dxe`.

Ce inseamna asta:

- sunt bune ca referinta pentru algoritm
- sunt bune ca referinta pentru simulare cu fisiere `.dat`
- nu sunt suficiente singure pentru tema finala

Motivul:

- nu au logica de comanda STM32 -> DSP
- nu au selectia de mod prin `current_command`
- nu au maparea parametrilor din `SW7..SW0` ca in proiectul final
- folosesc parametri fixi sau configurare mult mai simpla

## 1. test_AGC

Fisier principal:

- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/Visual DSP/test_AGC/agc.asm`

Are:

- proiect complet VisualDSP
- `ADSP-2181.ldf`
- `agc.dpj`
- fisiere de test:
  - `Debug/input_agc.dat`
  - `Debug/output_agc.dat`

Ce implementeaza:

- AGC simplu, standalone
- intrare din `rx_buf+2`
- iesire in `tx_buf+2`
- parametri fixi:
  - `M = 4`
  - `K = 2`
  - `ref = 0.5r`
  - `mu = 0.05r`

Cum ajuta:

- foarte bun pentru a intelege ideea AGC
- bun ca model de flux `input -> procesare -> output`

Ce lipseste fata de proiectul mare:

- nu are selectie de canal left/right
- nu are selectie de parametri din switch-uri
- nu are selectie de mod AGC/ALE/MF
- bufferul si scalarea sunt mai simple decat in implementarea finala

## 2. test_ALE

Fisiere principale:

- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/Visual DSP/test_ALE/ALE_TEST.DSP`
- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/Visual DSP/test_ALE/ALE_FCT.DSP`
- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/Visual DSP/test_ALE/ALE_IO.DSP`
- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/Visual DSP/test_ALE/ALE.H`

Are:

- proiect complet VisualDSP
- fisier de link editare propriu
- fisiere de test:
  - `Debug/input_ALE.dat`
  - `Debug/output_ALE.dat`

Ce implementeaza:

- ALE cu FIR + LLMS
- structura modulara:
  - test/ISR
  - functii FIR + LLMS
  - I/O separat

Parametri fixi din `ALE.H`:

- `n = 256`
- `delay = 128`
- `mu = 0.01r`
- `lambda = 0.01r`

Cum ajuta:

- este cea mai buna referinta pentru ALE
- separa clar partea de algoritm de partea de I/O
- te ajuta sa intelegi de ce in proiectul mare avem:
  - `process_ale`
  - `fir_ale`
  - `llms_ale`

Observatie:

- la build apar doar warning-uri de debug pentru lipsa etichetelor `.end`
- functional, proiectul este OK

Ce lipseste fata de proiectul mare:

- nu are selectie de parametri din switch-uri
- nu are selectie de mod
- nu are selectie de canal
- nu are integrarea cu afisarea si comanda de pe STM32

## 3. test_MF

Fisier principal:

- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/Visual DSP/test_MF/median.asm`

Are:

- proiect complet VisualDSP
- `ADSP-2181.ldf`
- `median_filter.dpj`
- fisiere de test:
  - `Debug/input_imp.dat`
  - `Debug/output_imp.dat`

Ce implementeaza:

- filtru median simplu
- sortare prin selectie
- fereastra fixa:
  - `W = 3`
  - `K = 1`

Cum ajuta:

- foarte bun pentru a intelege filtrul median
- foarte bun ca sursa pentru partea de sortare

Ce lipseste fata de proiectul mare:

- in proiectul final fereastra este selectabila
- in proiectul final `K` este ales din tabele
- nu exista selectie de canal sau de mod

## Ce trebuie folosit din ele

Merita folosite ca referinta:

- AGC: structura de baza a adaptarii castigului
- ALE: FIR + LLMS si organizarea pe functii
- MF: sortarea si selectia medianei

Nu merita copiate direct ca solutie finala:

- ISR-ul complet
- configurarea fixa a parametrilor
- logica de test standalone in locul decodarii de comenzi

## Concluzie pentru proiectul tau

Exemplele sunt bune si utile.

Nu trebuie refacute ca proiecte de test.

Trebuie doar intelese corect:

- ele valideaza algoritmii separat
- proiectul final adauga:
  - decodare comanda
  - selectie de canal
  - selectie de parametri
  - integrare STM32 + DSP

Practic:

- daca vrei sa verifici doar algoritmul, foloseste exemplele
- daca vrei sa verifici tema finala, foloseste `test_ext.asm`

