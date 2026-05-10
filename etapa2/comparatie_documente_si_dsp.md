# Comparatie etapa 2: 05-2, 07-2, 15-2

Data comparatie: 2026-05-09

## Concluzie scurta

Pentru cerinta oficiala, cel mai corect document ca logica DSP este `07-2.pdf`, deoarece foloseste maparea comenzii asa cum apare in schema:

- `D7-D6 = 11` pentru validare
- `D5-D4` selecteaza algoritmul: `00=AGC`, `01=ALE`, `10=MF`, `11=bypass`
- `D3` selecteaza canalul
- `D2-D0` reprezinta ID-ul DSP-ului tinta

`15-2.pdf` este foarte bun ca nivel de completitudine pentru algoritmi, citire switch-uri si afisare, dar codul lui nu valideaza corect ID-ul DSP si muta partea de procesare in intreruperea de timer, nu direct in `SPORT0 RX`.

`05-2.pdf` este cel mai putin potrivit daca se respecta strict cerinta din figura, pentru ca interpreteaza `D2-D0` ca ID de functie si `D5-D4` ca parametru. Asta intra in conflict cu formatul de comanda descris in `07-2.pdf` si `15-2.pdf`.

Recomandare practica: foloseste `07-2.pdf` ca model pentru parsarea comenzii si pentru faptul ca procesarea se face in `input_samples` / `SPORT0 RX`, dar ia din `15-2.pdf` ideile de citire `SW7-SW0`, update afisaj si bypass pe canalul neprocesat.

## Diferente in documentatie

| Zona comparata | 05-2.pdf | 07-2.pdf | 15-2.pdf | Observatie |
| --- | --- | --- | --- | --- |
| Format comanda | `D7-D6` validare, `D5-D4` parametru, `D3` canal, `D2-D0` functie | `D7-D6` validare, `D5-D4` algoritm, `D3` canal, `D2-D0` ID DSP | In descriere: `D5-D4` algoritm, `D3` canal, `D2-D0` ID DSP | `07-2` si descrierea din `15-2` sunt aliniate cu cerinta; `05-2` difera. |
| Exemple comenzi | `0xC0=AGC`, `0xC1=ALE`, `0xC2=MF` | `0xC1=AGC stanga`, `0xD1=ALE stanga`, `0xE1=MF stanga` pentru ID DSP `001` | Codul final merge pe `D5-D4` pentru functie, dar nu valideaza ID-ul DSP | Daca ID-ul DSP este `001`, exemplele din `07-2` sunt cele mai clare. |
| Rol ID DSP | Nu exista separat; este folosit ca functie | Este validat explicit: `D2-D0 == 001` | Este descris in text, dar in cod devine `param_id` si nu este validat | `07-2` respecta cel mai bine ideea de adresare a unui DSP anume. |
| Organizare DSP | Are cod separat pentru AGC/ALE/MF si apoi cod unificat | Codul DSP este prezentat mai compact, cu ISR `SPORT0 RX` ca flux principal | Are sectiune initiala cu bypass si apoi cod final complet | `15-2` e cel mai amplu; `07-2` e mai coerent pe fluxul de executie. |
| Intrerupere IA | Seteaza `Flag_CDA` | Seteaza `Flag_CDA` pe IRQ2 | Seteaza `Flag_CDA`, dar in final apare pe IRQL0 in tabel | Toate au ideea corecta, dar difera vectorul folosit. Trebuie pastrat vectorul conectat fizic la IA. |
| Procesare audio | In codul final, algoritmii sunt apelati din `isr_periodic` / timer, iar `SPORT0 RX` doar scrie `y_out` | Algoritmii sunt apelati in `input_samples` / `SPORT0 RX` | Similar cu `05-2`: algoritmii sunt apelati din timer, `SPORT0 RX` scrie rezultatul | `07-2` este mai corect pentru procesare sample-by-sample. |
| Parametri din `SW7-SW0` | Implementati prin `read_extension` si `apply_sw_params` | In codul unificat nu se vede clar citirea `PORT_IN` pentru parametri | Implementati prin `read_extension` si `apply_sw_params` | `05-2` si `15-2` sunt mai bune aici. |
| Iesire stereo | Scrie canalul procesat si lasa celalalt canal in bypass | `write_out` scrie doar canalul procesat; celalalt poate ramane vechi daca nu este actualizat separat | Scrie canalul procesat si lasa celalalt canal in bypass | `15-2` si `05-2` sunt mai bune aici. |
| AGC/ALE/MF | Implementari complete, dar cu mapare de comanda discutabila | Implementari mai apropiate de teoria din cerinta, inclusiv ALE mai mare (`N=256`, `D=128`) | Implementari complete si explicate pe larg | `15-2` este cel mai complet ca raport; `07-2` este cel mai corect ca arhitectura de rulare. |

## Observatii pe fiecare document

### 05-2.pdf

Puncte bune:
- are cod final unificat, nu doar bucati separate;
- are `read_extension`, `apply_sw_params` si `update_display`;
- trateaza canalul neprocesat ca bypass.

Probleme:
- foloseste `D2-D0` pentru selectie functie, desi in cerinta din celelalte documente acesti biti sunt ID DSP;
- nu valideaza un ID DSP tinta;
- face procesarea algoritmilor in `isr_periodic` / timer, nu in intreruperea de esantion `SPORT0 RX`;
- `y_out` poate fi decalat fata de esantionul curent, fiind calculat separat de momentul receptiei audio.

Verdict: bun ca sursa de idei pentru parametri si afisaj, dar nu este cel mai corect pentru formatul oficial al comenzii.

### 07-2.pdf

Puncte bune:
- descrie corect structura comenzii: `D5-D4` algoritm, `D3` canal, `D2-D0` ID DSP;
- valideaza `D7-D6`;
- verifica ID-ul DSP (`D2-D0 == 001`);
- ruleaza logica principala in `input_samples`, adica in ISR-ul `SPORT0 RX`, ceea ce este potrivit pentru prelucrare audio sample-by-sample;
- reseteaza starile algoritmilor cand se schimba comanda.

Probleme:
- ID-ul DSP este hardcodat la `001`; trebuie schimbat daca DSP-ul tau are alt ID;
- in codul prezentat nu se vede clar citirea `SW7-SW0` pentru parametrii algoritmilor;
- `write_out` pare sa scrie doar canalul procesat, fara sa copieze explicit celalalt canal in bypass;
- in PDF apare un `jump skip` inainte de initializarea codec-ului; daca acel salt exista si in codul real, trebuie eliminat sau justificat.

Verdict: cel mai corect ca interpretare a cerintei si ca flux DSP, dar trebuie completat cu parametri din switch-uri si bypass explicit pentru canalul neprocesat.

### 15-2.pdf

Puncte bune:
- descrierea initiala a comenzii este aliniata cu cerinta: `D5-D4` algoritm, `D3` canal, `D2-D0` ID DSP;
- codul final are implementari AGC/ALE/MF extinse;
- are `read_extension`, `apply_sw_params`, `update_display`;
- pastreaza canalul neprocesat in bypass.

Probleme:
- in codul final, `D2-D0` devine `param_id`, nu ID DSP validat;
- nu apare o verificare de tip `ID DSP == ID-ul meu`;
- procesarea se face in `isr_periodic` / timer, nu direct in `SPORT0 RX`;
- exista o contradictie intre documentatie si cod: textul spune ID DSP, codul trateaza acei biti ca parametru/diagnostic.

Verdict: cel mai complet ca material explicativ si algoritmi, dar nu la fel de curat ca `07-2.pdf` pentru formatul comenzii si timing-ul audio.

## Raportat la codul tau local

Codul tau din `DSP test/DSP test/test_ext/test_ext.asm` are cateva parti foarte bune:

- proceseaza in `input_samples`, deci este mai aproape de varianta corecta din `07-2.pdf`;
- citeste switch-urile din `PORT_IN`;
- are tabele pentru parametrii AGC/ALE/MF;
- scrie canalul procesat si lasa celalalt canal in bypass.

Actualizare dupa completarea codului: `test_ext.asm` foloseste acum maparea din `07-2.pdf`:

- `D5-D4` devin `current_mode` / algoritm;
- `D2-D0` devin `target_dsp_id`;
- comanda este valida daca `D7-D6 == 11` si `target_dsp_id` este ID-ul DSP-ului tau;
- `D5-D4 == 00` -> AGC;
- `D5-D4 == 01` -> ALE;
- `D5-D4 == 10` -> MF;
- `D5-D4 == 11` -> bypass.

Exemple pentru DSP cu ID `001`:

| Actiune | Comanda |
| --- | --- |
| AGC stanga | `0xC1` |
| AGC dreapta | `0xC9` |
| ALE stanga | `0xD1` |
| ALE dreapta | `0xD9` |
| MF stanga | `0xE1` |
| MF dreapta | `0xE9` |

## Clasament recomandat

1. `07-2.pdf` - cel mai corect pentru cerinta oficiala, mai ales la parsarea comenzii si rularea in `SPORT0 RX`.
2. `15-2.pdf` - cel mai complet pentru algoritmi, parametri si explicatii, dar trebuie corectat la validarea ID DSP si la fluxul de intreruperi.
3. `05-2.pdf` - util pentru idei de implementare, dar maparea comenzii este diferita de cerinta.

## Ce as lua pentru implementarea finala

- Din `07-2.pdf`: structura comenzii, validarea ID DSP, rularea in `input_samples`.
- Din `15-2.pdf`: citirea `SW7-SW0`, update afisaj, bypass pe canalul neprocesat, explicatiile algoritmilor.
- Din codul tau local: tabelele de parametri si organizarea deja curata a functiilor `configure_agc`, `configure_ale`, `configure_mf`, `process_agc`, `process_ale`, `process_mf`.
