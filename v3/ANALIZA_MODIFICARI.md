# Analiza modificarilor pentru `v3`

Am analizat:

- `c:\Users\alexg\Downloads\05-1.pdf`
- `c:\Users\alexg\Downloads\15-1.pdf`
- `Tema P2-2026.pdf`
- `Setarea intreruperilor.pdf`
- `IO Streams Simulating.pdf`
- `Interrupts Simulating.pdf`
- `plot.pdf`
- `adsp21xx._instruction_set.pdf`

## Ce am urmarit din documentele din folderul principal

- `Tema P2-2026.pdf` a ramas documentul de referinta pentru cerinta de baza.
- `Setarea intreruperilor.pdf` confirma folosirea lui `TIM2`, a callback-ului `HAL_TIM_PeriodElapsedCallback()` si a pornirii cu `HAL_TIM_Base_Start_IT(&htim2)`.
- `IO Streams Simulating.pdf`, `Interrupts Simulating.pdf` si `plot.pdf` confirma partea de testare si simulare in VisualDSP++, nu schimba formatul functional al comenzii.
- `adsp21xx._instruction_set.pdf` confirma sintaxa de asamblare ADSP-21xx si stilul rutinelor adaptive.

## Ce am considerat valid din documentatii

- STM32 foloseste `TIM2` pentru esantionare periodica.
- Masina de stari ARM are trei stari: asteptare eliberare `PRG`, asteptare apasare `PRG`, transmitere comanda.
- DSP-ul primeste comanda asincron si proceseaza audio pe baza functiei selectate.
- Functiile relevante raman `AGC`, `ALE` si `MF`.

## Ce am considerat inconsistent sau incomplet

- `05-1.pdf` lasa functiile DSP efective pe `TODO`, deci nu poate fi sursa completa pentru implementare.
- `15-1.pdf` propune o mapare a bitilor comenzii care intra in conflict cu exemplele de comenzi folosite in proiect (`0xC0`, `0xC1`, `0xC2`, `0xC8`, `0xC9`, `0xCA`) si cu decodarea deja existenta in DSP.
- Din acest motiv am pastrat pe DSP interpretarea coerenta cu exemplele functionale: `D2..D0 = functie`, `D3 = canal`, `D7..D6 = validare`.

## Ce am modificat in `main.c`

1. Am corectat momentul in care se memoreaza comanda.
   In varianta initiala, la apasarea lui `PRG` se trecea doar in starea de transmitere, iar octetul transmis era cel mai recent esantion citit ulterior. Asta putea duce la trimiterea unei alte comenzi daca utilizatorul schimba butoanele intre doua tick-uri.

2. Am introdus o comanda latenta (`g_pendingCommand`).
   Acum, exact cand este detectata apasarea lui `PRG`, comanda este construita si memorata. In starea urmatoare se transmite exact acea valoare, nu una citita mai tarziu.

3. Am construit explicit comanda cu `D7` si `D6` pe `1`.
   Aceasta alegere este sustinuta de ambele PDF-uri noi, care trateaza acesti doi biti ca biti de validare.

## Ce am modificat in scripturile MATLAB

1. Am facut incarcarea fisierelor independenta de directorul curent.
   Scripturile folosesc acum calea folderului in care se afla ele, nu `pwd`.

2. Am corectat denumirea pentru fisierul ALE.
   Scriptul folosea `input_ale.dat`, dar in proiect fisierul existent este `input_ALE.dat`.

3. Am facut dimensiunea semnalului dependenta de fisierul incarcat.
   Astfel scripturile nu mai presupun orbeste o lungime fixa.

4. Comentariile noi introduse de mine sunt in romana.

## Ce nu am schimbat pe DSP

- Nu am rescris algoritmul integrat din `test_ext.asm`, pentru ca varianta ta curenta este mai completa decat cea din `05-1.pdf` si mai coerenta decat varianta conflictuala din `15-1.pdf`.
- Am pastrat implementarea DSP care deja integreaza `AGC`, `ALE` si `MF` in acelasi program.

## Verificare helper functions

- In `main.c` toate helper-ele STM32 folosite sunt acum complete: `ARM_ReadCommand`, `ARM_BuildCommand`, `ARM_WriteLedBus`, `ARM_WriteCommandBus`, `ARM_TransmitCommand`.
- In scripturile MATLAB nu au ramas apeluri la fisiere helper cu nume gresite.
- In implementarea DSP integrata din `test_ext.asm` nu au ramas helper functions marcate explicit ca `TODO`.
