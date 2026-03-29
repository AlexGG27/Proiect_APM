# Ghid Proiect - Explicatii Pas cu Pas si Intrebari Posibile

## 1. Ideea generala a proiectului

Proiectul are doua parti principale:

1. `STM32`
2. `DSP ADSP-2181`

Rolul lor este diferit:

- `STM32` citeste comanda de la utilizator si o transmite spre DSP.
- `DSP` primeste comanda, alege functia ceruta si prelucreaza semnalul audio.

Functiile implementate pe DSP sunt:

- `AGC` = Automatic Gain Control
- `ALE` = Adaptive Line Enhacer
- `MF` = Median Filter

Daca o comanda nu este valida, DSP face `bypass`, adica:

```text
out = in
```

Adica iesirea ramane egala cu intrarea, fara prelucrare.

---

## 2. Fluxul complet al sistemului

Pas cu pas, proiectul functioneaza asa:

1. Utilizatorul pune o valoare pe `B7..B0` si actioneaza `PRG` pe STM32.
2. STM32 citeste periodic acesti pini cu `TIM2`.
3. O masina de stari detecteaza o apasare valida a lui `PRG`.
4. La momentul potrivit, STM32 pune comanda pe magistrala `PCDA7..PCDA0`.
5. DSP vede comanda si butonul `IA` prin `IRQ2`.
6. DSP seteaza `flag_cda = 1`.
7. La urmatoarea intrerupere periodica de esantionare, DSP citeste comanda.
8. DSP verifica daca este valida.
9. DSP determina:
   - canalul
   - functia
   - parametrii din switch-uri
10. DSP ruleaza pentru fiecare esantion:
   - `AGC`
   - sau `ALE`
   - sau `MF`
   - sau `bypass`

---

## 3. Partea STM32 explicata pas cu pas

Fisier principal:

- [main.c](C:/Users/alexg/Desktop/Proiect_APM/Proiect_APM/test_P2_STM32_2026/test/Core/Src/main.c)

### 3.1. Ce face STM32

STM32 nu proceseaza audio. El are doar rolul de:

- citire comanda
- detectie apasare `PRG`
- afisare comanda pe LED-uri
- trimitere comanda pe magistrala catre DSP

### 3.2. Masina de stari de pe STM32

In cod exista:

```c
typedef enum
{
  ARM_STATE_WAIT_PRG_LOW = 0,
  ARM_STATE_WAIT_PRG_HIGH,
  ARM_STATE_SEND_COMMAND
} ArmState_t;
```

Semnificatie:

- `WAIT_PRG_LOW`
  - asteapta eliberarea lui `PRG`
- `WAIT_PRG_HIGH`
  - dupa eliberare, asteapta o noua apasare
- `SEND_COMMAND`
  - transmite comanda catre DSP

### 3.3. De ce exista aceasta masina de stari

Fara aceasta masina de stari, daca utilizatorul tine butonul apasat:

- comanda ar putea fi transmisa de foarte multe ori

Cu masina de stari:

- comanda este transmisa o singura data pentru o apasare valida

### 3.4. Ce face TIM2

`TIM2` este folosit ca baza de timp.

El produce o intrerupere periodica. In callback:

```c
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  (void)htim;
  g_sampledCommand = ARM_ReadCommand();
  g_prgLevel = ARM_ReadPrg();
  g_tickReady = 1U;
}
```

Observatie foarte importanta:

- callback-ul nu executa toata logica
- callback-ul doar citeste intrarile
- logica propriu-zisa se face in `main`

Asta este bine pentru ca:

- ISR-ul ramane scurt
- comportamentul este mai predictibil
- codul este mai usor de explicat

### 3.5. Cum se citeste comanda

Codul:

```c
static uint8_t ARM_ReadCommand(void)
{
  return (uint8_t)((GPIOA->IDR >> 1U) & 0x00FFU);
}
```

Explicatie:

- `B0..B7` sunt pe `PA1..PA8`
- se face shift la dreapta cu 1
- apoi se pastreaza doar 8 biti

### 3.6. Cum se citeste PRG

Codul:

```c
static uint8_t ARM_ReadPrg(void)
{
  return (uint8_t)((GPIOA->IDR >> 9U) & 0x01U);
}
```

Explicatie:

- `PRG` este pe `PA9`
- bitul este adus pe pozitia 0

### 3.7. Cum se scrie comanda spre DSP

Codul:

```c
static void ARM_WriteOutputBus(uint8_t value)
{
  GPIOB->ODR = (uint16_t)(((uint16_t)value << 8U) | value);
}
```

Explicatie:

- byte-ul de jos merge pe `PB7..PB0` = `LED7..LED0`
- byte-ul de sus merge pe `PB15..PB8` = `PCDA7..PCDA0`

Deci aceeasi comanda este:

- vazuta pe LED-uri
- trimisa si la DSP

### 3.8. Cum se executa masina de stari

Functia importanta este:

```c
static void ARM_ProcessTick(uint8_t sampledCommand, uint8_t prgLevel)
{
  g_armState = ARM_NextState(g_armState, prgLevel);

  if (g_armState == ARM_STATE_SEND_COMMAND)
  {
    ARM_WriteOutputBus(sampledCommand);
    g_armState = ARM_STATE_WAIT_PRG_LOW;
  }
}
```

Explicatie:

1. Se calculeaza starea urmatoare in functie de `PRG`.
2. Daca s-a ajuns in `SEND_COMMAND`, se transmite comanda.
3. Dupa transmitere, se revine in starea initiala.

### 3.9. Configurarea de ceas

`SystemClock_Config()` pune placa la `72 MHz`.

Ideea este:

- sursa externa `HSE`
- `PLL x9`
- `SYSCLK = 72 MHz`

### 3.10. Configurarea lui TIM2

Valori importante:

- `Prescaler = 7199`
- `Period = 100`

Asta inseamna:

- 72 MHz / 7200 = 10 kHz
- 10 kHz / 101 ≈ 99 Hz

Deci aproximativ 100 de intreruperi pe secunda.

---

## 4. Partea DSP explicata pas cu pas

Fisier principal:

- [test_ext.asm](C:/Users/alexg/Desktop/Proiect_APM/Proiect_APM/DSP%20test/DSP%20test/test_ext/test_ext.asm)

### 4.1. Ce face DSP-ul

DSP-ul:

- initializeaza codec-ul si SPORT0
- asteapta comenzi
- citeste esantioane audio
- decide ce functie ruleaza
- proceseaza doar canalul selectat

### 4.2. Variabile importante

Variabile centrale:

- `flag_cda`
  - indica daca a venit o comanda noua
- `current_command`
  - comanda curenta
- `current_switches`
  - valorile switch-urilor pentru parametri
- `current_mode`
  - functia curenta
- `current_channel`
  - canalul curent

### 4.3. Modurile definite

```asm
#define MODE_AGC        0
#define MODE_ALE        1
#define MODE_MF         2
#define MODE_BYPASS     3
```

### 4.4. Ce inseamna `flag_cda`

Cand utilizatorul apasa `IA`, apare intreruperea asincrona:

```asm
cmd_interrupt:
        ax0 = 1;
        dm(flag_cda) = ax0;
        rti;
```

Adica:

- DSP nu decodeaza comanda chiar in aceasta intrerupere
- doar marcheaza ca exista o comanda noua

Asta este o alegere buna pentru ca:

- intreruperea ramane scurta
- decodarea se face sincron cu fluxul audio

### 4.5. Intreruperea periodica de esantionare

Rutina principala este:

```asm
input_samples:
```

Acolo se fac 2 lucruri:

1. se citesc esantioanele stanga si dreapta
2. se alege intre:
   - `starea 1`: exista comanda noua
   - `starea 2`: se ruleaza functia curenta

### 4.6. Starea 1

Cand `flag_cda = 1`:

- se apeleaza `latch_command`
- se citeste comanda
- se citesc switch-urile
- se determina canalul
- se valideaza comanda
- se configureaza algoritmul

### 4.7. Starea 2

Cand `flag_cda = 0`:

- se prelucreaza efectiv semnalul audio

Mai intai se alege canalul:

- `left`
- sau `right`

Apoi se intra in:

- `run_agc`
- `run_ale`
- `run_mf`
- sau `bypass_output`

---

## 5. Formatul comenzii

In DSP ai:

```asm
#define CMD_VALID_MASK   0x00C0
#define CMD_VALID_BITS   0x00C0
#define CMD_ID_MASK      0x0007
#define CMD_CHANNEL_MASK 0x0008
```

Explicatie:

- `D7` si `D6` trebuie sa fie `1`
- `D3` selecteaza canalul
- `D2..D0` selecteaza functia

### 5.1. Canalul

In cod:

```asm
ax0 = dm(current_command);
ay0 = CMD_CHANNEL_MASK;
ar = ax0 and ay0;
if eq jump cmd_left_channel;
```

Deci:

- `D3 = 0` -> canal stanga
- `D3 = 1` -> canal dreapta

### 5.2. Functia

```asm
ax0 = dm(current_command);
ay0 = CMD_ID_MASK;
ar = ax0 and ay0;
dm(current_mode) = ar;
```

Deci:

- `0` -> AGC
- `1` -> ALE
- `2` -> MF

### 5.3. Exemple de comenzi

- `0xC0` = AGC left
- `0xC1` = ALE left
- `0xC2` = MF left
- `0xC8` = AGC right
- `0xC9` = ALE right
- `0xCA` = MF right

### 5.4. Comanda invalida

Daca:

- `D7 D6` nu sunt `11`
- sau ID-ul nu este `0, 1, 2`

atunci:

```asm
set_bypass_mode:
        ax0 = MODE_BYPASS;
        dm(current_mode) = ax0;
```

---

## 6. AGC explicat simplu

Fisierul final foloseste:

- [process_agc](C:/Users/alexg/Desktop/Proiect_APM/Proiect_APM/DSP%20test/DSP%20test/test_ext/test_ext.asm#L583)

### 6.1. Scop

`AGC` mentine amplitudinea semnalului in jurul unei valori tinta.

Daca semnalul este prea mic:

- castigul creste

Daca semnalul este prea mare:

- castigul scade

### 6.2. Ideea matematica

Se calculeaza:

```text
y(n) = g(n-1) * x(n)
```

unde:

- `x(n)` este intrarea
- `g(n-1)` este castigul curent
- `y(n)` este iesirea

Apoi se estimeaza nivelul mediu al iesirii si se compara cu o referinta:

```text
eroare = ref - nivel_mediu
```

Castigul este actualizat cu un pas de adaptare `mu`.

### 6.3. Ce parametri are

Din switch-uri se aleg:

- `agc_ref`
- `agc_count`
- `agc_shift`
- `agc_mu`

### 6.4. Ce te pot intreba la AGC

Intrebare:
Ce face AGC?

Raspuns:
AGC mentine amplitudinea semnalului aproape de o valoare de referinta prin adaptarea automata a castigului.

Intrebare:
De ce ai nevoie de `mu`?

Raspuns:
`mu` este pasul de adaptare. Daca este mare, sistemul reactioneaza repede, dar poate deveni instabil. Daca este mic, adaptarea este mai lenta, dar mai stabila.

Intrebare:
Ce reprezinta `ref`?

Raspuns:
`ref` este nivelul tinta al amplitudinii iesirii.

Intrebare:
De ce folosesti o medie pe mai multe esantioane?

Raspuns:
Ca sa nu modific castigul prea brusc de la un singur esantion la altul.

---

## 7. MF explicat simplu

Fisierul final foloseste:

- [process_mf](C:/Users/alexg/Desktop/Proiect_APM/Proiect_APM/DSP%20test/DSP%20test/test_ext/test_ext.asm#L660)

### 7.1. Scop

`MF` = Median Filter.

Este bun pentru eliminarea zgomotului impulsiv:

- spike-uri
- impulsuri scurte
- valori aberante

### 7.2. Ideea matematica

Se ia o fereastra de `W` esantioane:

```text
[x1, x2, x3, ..., xW]
```

Se sorteaza si se alege elementul median:

```text
median(x1, x2, ..., xW)
```

### 7.3. De ce functioneaza

O valoare impulsiva foarte mare sau foarte mica nu ajunge in centru dupa sortare, deci este eliminata usor.

### 7.4. Ce parametri are

Din switch-uri se aleg:

- `mf_window`
- `mf_k_index`

In implementarea ta:

- se copiaza fereastra
- se sorteaza cu selectie
- se alege elementul dorit

### 7.5. Ce te pot intreba la MF

Intrebare:
De ce nu ai folosit un filtru liniar?

Raspuns:
Pentru zgomot impulsiv, filtrul median este mai bun pentru ca elimina valorile extreme fara sa fie influentat mult de ele.

Intrebare:
De ce sortezi fereastra?

Raspuns:
Pentru a putea extrage valoarea mediana.

Intrebare:
Ce dezavantaj are filtrul median?

Raspuns:
Este mai costisitor computational decat un filtru liniar simplu, pentru ca trebuie sa sorteze valorile din fereastra.

---

## 8. ALE explicat simplu

Fisierul final foloseste:

- [process_ale](C:/Users/alexg/Desktop/Proiect_APM/Proiect_APM/DSP%20test/DSP%20test/test_ext/test_ext.asm#L751)

### 8.1. Scop

`ALE` este un filtru adaptiv care incearca sa extraga componenta predictibila a semnalului.

Este util pentru:

- semnale corelate in timp
- reducerea zgomotului intr-o maniera adaptiva

### 8.2. Ideea generala

ALE foloseste:

- o linie de intarziere
- un filtru FIR adaptiv
- o regula de adaptare de tip LMS / leaky LMS

In implementarea ta:

1. se genereaza o componenta de zgomot
2. se obtine o intrare perturbata
3. filtrul FIR estimeaza componenta predictibila
4. coeficientii filtrului sunt adaptati iterativ

### 8.3. De ce se numeste adaptiv

Pentru ca:

- coeficientii filtrului nu sunt fixi
- ei se modifica in timp in functie de eroare

### 8.4. Ce parametri are

Din switch-uri se aleg:

- `ale_delay`
- `ale_a`
- `ale_mu`
- `ale_lambda`

### 8.5. Ce te pot intreba la ALE

Intrebare:
Care este diferenta fata de un FIR normal?

Raspuns:
La un FIR normal coeficientii sunt ficsi. La ALE coeficientii sunt adaptati automat pe baza erorii.

Intrebare:
Ce rol are `delay`?

Raspuns:
Intarzierea separa componenta corelata a semnalului de componenta mai putin corelata, ajutand filtrul sa invete mai bine semnalul util.

Intrebare:
Ce rol are `lambda`?

Raspuns:
`lambda` introduce o componenta de tip leak, care ajuta la stabilitate si previne cresterea necontrolata a coeficientilor.

---

## 9. De ce sunt unite toate trei in acelasi program

Tema nu cere 3 proiecte DSP separate, ci un singur program care:

- primeste comanda
- identifica functia
- aplica prelucrarea corespunzatoare

De aceea `test_ext.asm` contine:

- logica de receptie comanda
- logica de selectie canal
- logica de selectie functie
- cele 3 algoritme

---

## 10. Intrebari posibile la sustinere si raspunsuri

### Intrebare 1
Care este rolul STM32 in proiect?

Raspuns:
STM32 citeste comanda de la utilizator, o valideaza prin masina de stari bazata pe `PRG`, o afiseaza pe LED-uri si o transmite catre DSP pe magistrala `PCDA`.

### Intrebare 2
Care este rolul DSP-ului?

Raspuns:
DSP-ul primeste comanda, selecteaza functia `AGC`, `ALE` sau `MF`, configureaza parametrii si prelucreaza in timp real semnalul audio.

### Intrebare 3
De ce folosesti o intrerupere periodica pe STM32?

Raspuns:
Pentru a esantiona periodic si controlat intrarile `B7..B0` si `PRG`, fara polling haotic.

### Intrebare 4
De ce nu ai pus toata logica in callback-ul lui TIM2?

Raspuns:
Pentru ca ISR-ul trebuie sa fie cat mai scurt. Callback-ul doar citeste intrarile si semnalizeaza ca exista date noi, iar logica automata este executata in bucla principala.

### Intrebare 5
Ce face `flag_cda` pe DSP?

Raspuns:
`flag_cda` marcheaza faptul ca a venit o comanda noua prin `IRQ2`. Decodarea comenzii se face ulterior, sincronizat cu intreruperea periodica de esantionare.

### Intrebare 6
Cum validezi comanda pe DSP?

Raspuns:
Verific ca bitii `D7` si `D6` sa fie `1` si ca ID-ul functiei sa fie `0`, `1` sau `2`. Daca una dintre aceste conditii nu este indeplinita, trec in `bypass`.

### Intrebare 7
Cum selectezi canalul?

Raspuns:
Canalul este ales din bitul `D3` al comenzii. `0` inseamna canal stanga, `1` inseamna canal dreapta.

### Intrebare 8
De ce lasi celalalt canal nemodificat?

Raspuns:
Pentru ca tema cere selectie de canal. Se prelucreaza doar canalul selectat, iar celalalt este trecut direct la iesire.

### Intrebare 9
Ce se intampla daca o comanda este invalida?

Raspuns:
DSP intra in `MODE_BYPASS`, deci iesirea devine egala cu intrarea.

### Intrebare 10
Ce afiseaza display-ul de pe DSP?

Raspuns:
Display-ul afiseaza functia selectata. In implementare, se foloseste si bitul canalului pentru a distinge usor stanga/dreapta.

### Intrebare 11
De ce ai tabele de parametri?

Raspuns:
Pentru a mapa usor combinatii de switch-uri pe valori discrete de parametri pentru fiecare algoritm.

### Intrebare 12
Ce avantaj are AGC?

Raspuns:
Compenseaza variatiile de amplitudine ale semnalului si mentine un nivel de iesire mai constant.

### Intrebare 13
Ce avantaj are filtrul median?

Raspuns:
Este foarte bun pentru eliminarea zgomotului impulsiv si a valorilor aberante.

### Intrebare 14
Ce avantaj are ALE?

Raspuns:
Poate urmari adaptiv un semnal predictibil si poate reduce componente nedorite fara a avea coeficienti ficsi.

### Intrebare 15
De ce ai ales o arhitectura cu comanda separata de procesare?

Raspuns:
Pentru ca este modulara. STM32 se ocupa de interfata si comanda, iar DSP se ocupa doar de procesarea semnalului.

---

## 11. Raspuns foarte scurt, bun de spus la inceputul prezentarii

„Proiectul implementeaza un sistem cu STM32 si DSP in care STM32 citeste si transmite comanda, iar DSP selecteaza unul dintre cele trei algoritme de procesare, `AGC`, `ALE` sau `MF`, pe canalul ales. Daca o comanda nu este valida, sistemul trece in `bypass`, deci iesirea ramane egala cu intrarea.”

---

## 12. Ce sa inveti foarte bine

Daca vrei sa te descurci bine la intrebari, invata foarte bine urmatoarele:

1. Rolul exact al lui `TIM2` pe STM32
2. Masina de stari `WAIT_PRG_LOW -> WAIT_PRG_HIGH -> SEND_COMMAND`
3. Formatul comenzii DSP
4. Ce inseamna `flag_cda`
5. Diferenta intre `AGC`, `ALE` si `MF`
6. Ce inseamna `bypass`
7. Cum alegi canalul
8. De ce exista parametri selectati din switch-uri

---

## 13. Formula de memorie rapida

Poti retine proiectul asa:

```text
STM32:
citeste -> valideaza PRG -> transmite comanda

DSP:
primeste -> decodeaza -> selecteaza functie -> proceseaza audio
```

Si algoritmii:

```text
AGC = regleaza amplitudinea
ALE = filtru adaptiv
MF  = filtru median
```
