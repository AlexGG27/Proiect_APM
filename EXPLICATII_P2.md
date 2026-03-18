# Tema P2 - explicatii si pasi de lucru

## 1. Ce am implementat

### ARM STM32F103
- fisier proiect: `test_P2_STM32_2026/test/Core/Src/main.c`
- timerul `TIM2` face esantionarea periodica a intrarilor
- se citesc `B7...B0` si `PRG`
- programul urmareste automatul din figura MCU:
  - `0` = asteapta eliberarea lui `PRG`
  - `1` = asteapta apasarea lui `PRG`
  - `2` = transmite comanda
- la transmitere:
  - comanda este pusa pe `PCDA7...PCDA0`
  - aceeasi comanda este afisata pe `LED7...LED0`

### DSP ADSP-2181
- fisier proiect: `DSP test/DSP test/test_ext/test_ext.asm`
- s-a pastrat initializarea codec-ului AD1847 si lucrul pe `SPORT0`
- `IRQ2` este folosit ca intrerupere asincrona `IA`
- la `IA` se seteaza doar `Flag_CDA=1`
- in intreruperea periodica de esantionare:
  - daca `Flag_CDA=1`, DSP citeste comanda de pe `PF7...PF0`, citeste parametrii de pe `SW7...SW0`, actualizeaza modul si afisajul, apoi revine
  - daca nu exista comanda noua, DSP proceseaza semnalul pe canalul selectat cu:
    - `AGC`
    - `ALE`
    - `MF`
    - sau `bypass` daca mesajul este invalid

## 2. Formatul comenzii ARM -> DSP

Comanda are 8 biti:

| Bit | Semnificatie |
| --- | --- |
| D7 | trebuie sa fie `1` |
| D6 | trebuie sa fie `1` |
| D5 | `CDA1` - rezervat in implementarea mea |
| D4 | `CDA0` - rezervat in implementarea mea |
| D3 | `CANAL` |
| D2..D0 | `ID functie` |

O comanda este considerata valida daca:
- `D7 D6 = 11`
- `ID functie` este `000`, `001` sau `010`

Maparea functiilor:
- `000` = `AGC`
- `001` = `ALE`
- `010` = `MF`
- orice alt `ID` = `bypass`

Maparea canalului:
- `D3 = 0` -> canal stanga
- `D3 = 1` -> canal dreapta

Exemple rapide:
- `0xC0` = AGC pe stanga
- `0xC1` = ALE pe stanga
- `0xC2` = MF pe stanga
- `0xC8` = AGC pe dreapta
- `0xC9` = ALE pe dreapta
- `0xCA` = MF pe dreapta

## 3. Parametrii de pe SW7...SW0 (DSP)

### AGC
- `SW7..SW6` -> `REF`
  - `00` -> `0.25`
  - `01` -> `0.375`
  - `10` -> `0.5`
  - `11` -> `0.625`
- `SW5..SW4` -> `M`
  - `00` -> `4`
  - `01` -> `8`
  - `10` -> `16`
  - `11` -> `32`
- `SW3..SW2` -> `mu`
  - `00` -> `0.01`
  - `01` -> `0.02`
  - `10` -> `0.05`
  - `11` -> `0.1`
- `SW1..SW0` nu sunt folosite

### ALE
- `SW7..SW6` -> `D`
  - `00` -> `16`
  - `01` -> `32`
  - `10` -> `64`
  - `11` -> `128`
- `SW5..SW4` -> `a`
  - `00` -> `0`
  - `01` -> `0.125`
  - `10` -> `0.25`
  - `11` -> `0.5`
- `SW3..SW2` -> `mu`
  - `00` -> `0.005`
  - `01` -> `0.01`
  - `10` -> `0.02`
  - `11` -> `0.04`
- `SW1..SW0` -> `lambda`
  - `00` -> `0`
  - `01` -> `0.002`
  - `10` -> `0.005`
  - `11` -> `0.01`

### MF
- `SW1..SW0` -> `K`
  - `00` -> `1` -> `W=3`
  - `01` -> `2` -> `W=5`
  - `10` -> `3` -> `W=7`
  - `11` -> `4` -> `W=9`
- `SW7..SW2` nu sunt folosite

## 4. Afisari

### STM32
- `LED7...LED0` arata ultima comanda transmisa spre DSP

### DSP
- afisajul cu 7 segmente arata modul curent:
  - `0` = AGC
  - `1` = ALE
  - `2` = MF
  - `E` = comanda invalida / bypass
- punctul zecimal este aprins pentru canalul dreapta

Nota:
- in cod am folosit coduri de 7 segmente active-high, tip common-cathode
- daca placa ta are logica inversa, inversezi valorile din `display_table` din `test_ext.asm`

## 5. Pasi in STM32CubeIDE

1. Deschide proiectul `test_P2_STM32_2026/test`.
2. Verifica in `test.ioc` ca:
   - `TIM2` are intreruperile activate
   - `B0...B7` si `PRG` sunt intrari
   - `LED0...LED7` si `PCDA0...PCDA7` sunt iesiri
3. Deschide `Core/Src/main.c`.
4. Faci `Build`.
5. Programezi placa STM32.
6. Pentru utilizare:
   - setezi `B7...B0`
   - apesi `PRG`
   - verifici ca aceeasi valoare apare pe `LED7...LED0`
   - comanda ramane prezenta pe `PCDA7...PCDA0`

## 6. Pasi in VisualDSP++ 3.5

1. Deschide proiectul `DSP test/DSP test/test_ext/test_ext.dpj`.
2. Selecteaza configuratia `Debug`.
3. Faci `Build`.
4. Creezi sau deschizi o sesiune pentru `ADSP-2181`.
5. Incarci `Debug/test_ext.dxe`.
6. Pentru simularea fluxului audio:
   - folosesti `Settings -> Streams`
   - configurezi stream de intrare si iesire pe `SPORT0`
   - pentru date de test poti porni de la fisierele din:
     - `Exemple prelucrari de semnal/Exemple prelucrari de semnal/Visual DSP/test_AGC/Debug/input_agc.dat`
     - `Exemple prelucrari de semnal/Exemple prelucrari de semnal/Visual DSP/test_ALE/Debug/input_ALE.dat`
     - `Exemple prelucrari de semnal/Exemple prelucrari de semnal/Visual DSP/test_MF/Debug/input_imp.dat`
7. Pentru intreruperea asincrona `IA`:
   - folosesti `Settings -> Interrupts`
   - selectezi `IRQ2`
   - generezi manual sau periodic evenimentul

## 7. Testare simpla fara hardware complet pe DSP

In `test_ext.asm` exista 3 variabile pentru test:
- `debug_override_enable`
- `debug_command`
- `debug_switches`

Procedura:
1. In `Memory Window`, setezi `debug_override_enable = 1`.
2. Pui in `debug_command` o valoare ca `0x00C0`, `0x00C1`, `0x00C2`, `0x00C8`, `0x00C9`, `0x00CA`.
3. Pui in `debug_switches` combinatia de parametri dorita.
4. Generezi `IRQ2`.
5. DSP va folosi aceste valori in locul citirii fizice de pe `PF7...PF0` si `SW7...SW0`.

## 8. Secventa recomandata pe hardware

1. Pe STM32 setezi `B7...B0` pentru comanda.
2. Apesi `PRG` pe subsistemul ARM.
3. Verifici `LED7...LED0`.
4. Pe extensia DSP setezi `SW7...SW0` pentru parametri.
5. Apesi `IA` pe DSP.
6. Verifici afisajul cu 7 segmente.
7. Aplici semnalul audio la codec si observi iesirea.

## 9. Observatii importante

- Implementarea DSP interpreteaza `D5` si `D4` doar ca biti rezervati; validarea reala se face pe `D7 D6` si pe `ID functie`.
- La latch de comanda noua, starile interne AGC/ALE/MF sunt resetate ca sa pornesti curat pe noul set de parametri.
- Pentru `ALE`, zgomotul este generat intern cu un LFSR simplu si este scalat cu parametrul `a`.
- Pentru `AGC`, canalul neprocesat ramane in bypass.
- Pentru `MF`, se proceseaza doar canalul selectat, celalalt ramane nemodificat.

## 10. Limitari de verificare in mediul meu

- Nu am putut face build pentru DSP in acest mediu deoarece `easm218x.exe` cere licenta locala.
- Nu am putut face build pentru STM32 aici deoarece toolchain-ul `arm-none-eabi-gcc` nu este disponibil in PATH.
- Din cauza asta, explicatiile de mai sus sunt importante pentru validarea finala in IDE-urile tale.
