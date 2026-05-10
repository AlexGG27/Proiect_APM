# Intrebari si raspunsuri posibile - focus DSP

Acest fisier este gandit pentru pregatirea sustinerii proiectului. Intrebarile sunt din tot proiectul, dar accentul este pe subsistemul DSP ADSP-2181, pe codul `DSP test/DSP test/test_ext/test_ext.asm`, pe comunicatia cu ARM-ul si pe algoritmii AGC, ALE si MF.

Nota importanta: raspunsurile de mai jos sunt aliniate cu fisierul ASM activ. In documentatie apar uneori diferente fata de varianta activa, mai ales la citirea switch-urilor `SW7..SW0`, la `IRQL0` vs `IRQ2`, la scrierea ambelor canale si la dimensiunea ferestrei MF.

## 1. Arhitectura generala

### 1. Care este ideea generala a proiectului?
Proiectul implementeaza un sistem de procesare audio in timp real cu doua componente principale: STM32 pentru comanda si interfata cu utilizatorul, respectiv ADSP-2181 pentru prelucrarea digitala a semnalului.

### 2. De ce se foloseste un sistem cu doua procesoare?
Pentru separarea responsabilitatilor. STM32 se ocupa de butoane, LED-uri si transmiterea comenzii, iar DSP-ul se ocupa de procesarea audio, care necesita calcule rapide si repetitive.

### 3. Care este rolul STM32?
STM32 citeste intrarile utilizatorului, construieste octetul de comanda, il afiseaza pe LED-uri si il transmite spre DSP pe magistrala paralela `PCDA7..PCDA0`.

### 4. Care este rolul DSP-ului?
DSP-ul primeste comanda, o valideaza, selecteaza canalul si algoritmul, apoi proceseaza esantioanele audio primite de la CODEC prin `SPORT0`.

### 5. Care este rolul CODEC-ului AD1847?
CODEC-ul converteste semnalul audio analogic in esantioane digitale pentru DSP si apoi converteste inapoi iesirea digitala a DSP-ului in semnal analogic.

### 6. Ce algoritmi sunt implementati pe DSP?
Sunt implementati trei algoritmi: `AGC` pentru control automat al castigului, `ALE` pentru filtrare adaptiva si `MF` pentru filtrare mediana.

### 7. Ce inseamna bypass?
Bypass inseamna ca semnalul de intrare este copiat la iesire fara prelucrare. In cod, acesta este comportamentul pentru comenzi invalide sau pentru selectia `D5..D4 = 11`.

### 8. De ce procesarea audio se face pe DSP si nu pe STM32?
DSP-ul are arhitectura si instructiuni specializate pentru calcule de semnal, inclusiv operatii MAC, buffere circulare si acces rapid la memorie.

### 9. Ce inseamna procesare in timp real in acest proiect?
Inseamna ca la fiecare cadru audio primit de la CODEC, DSP-ul trebuie sa citeasca esantionul, sa aplice algoritmul selectat si sa scrie rezultatul suficient de repede pentru urmatorul cadru.

### 10. Care este fluxul complet al datelor?
Utilizatorul seteaza comanda pe STM32, STM32 o trimite pe `PCDA`, DSP o citeste prin `Prog_Flag_Data`, CODEC-ul trimite audio prin `SPORT0`, DSP proceseaza esantionul si scrie iesirea in `tx_buf`.

## 2. Comanda ARM -> DSP

### 11. Cum este structurat octetul de comanda?
Octetul are `D7-D6` pentru validare, `D5-D4` pentru selectia algoritmului, `D3` pentru canal si `D2-D0` pentru ID-ul DSP tinta.

### 12. Ce rol au bitii `D7` si `D6`?
Ei sunt biti de validare. Comanda este acceptata doar daca `D7-D6 = 11`, adica masca `0xC0` este prezenta.

### 13. Ce rol au bitii `D5-D4`?
Ei selecteaza algoritmul DSP: `00 = AGC`, `01 = ALE`, `10 = MF`, `11 = bypass`.

### 14. Ce rol are bitul `D3`?
Bitul `D3` selecteaza canalul audio. `0` inseamna canalul stang, iar `1` inseamna canalul drept.

### 15. Ce rol au bitii `D2-D0`?
Ei reprezinta ID-ul DSP-ului tinta. In codul activ, ID-ul valid este `001`.

### 16. De ce se valideaza ID-ul DSP?
Pentru ca aceeasi magistrala de comanda ar putea adresa mai multe DSP-uri. Fiecare DSP trebuie sa reactioneze doar la comenzile destinate lui.

### 17. Ce se intampla daca ID-ul nu este `001`?
Comanda este considerata invalida si codul intra pe ramura de bypass.

### 18. Ce comanda inseamna AGC pe canalul stang pentru ID `001`?
`0xC1`: `1100 0001`, unde `D7-D6=11`, algoritm `00`, canal `0`, ID `001`.

### 19. Ce comanda inseamna AGC pe canalul drept pentru ID `001`?
`0xC9`: `1100 1001`, unde bitul `D3` este `1`.

### 20. Ce comanda inseamna ALE pe canalul stang?
`0xD1`: `1101 0001`, unde `D5-D4=01`.

### 21. Ce comanda inseamna ALE pe canalul drept?
`0xD9`: `1101 1001`.

### 22. Ce comanda inseamna MF pe canalul stang?
`0xE1`: `1110 0001`, unde `D5-D4=10`.

### 23. Ce comanda inseamna MF pe canalul drept?
`0xE9`: `1110 1001`.

### 24. Ce comanda inseamna bypass pentru ID `001`?
`0xF1` pentru stanga sau `0xF9` pentru dreapta, deoarece `D5-D4=11`.

### 25. Unde se citeste comanda in codul DSP?
In rutina `input_samples`, daca `Flag_CDA` este diferit de zero, codul citeste `Prog_Flag_Data`, pastreaza doar octetul inferior si il salveaza in `PF_input`.

### 26. De ce se face masca `0x00FF` la citirea comenzii?
Pentru ca doar cei 8 biti `D7..D0` reprezinta comanda utila. Restul bitilor din registru sunt ignorati.

### 27. De ce nu se citeste comanda permanent?
Pentru eficienta si sincronizare. Comanda se citeste doar cand `Flag_CDA` indica faptul ca ARM-ul a trimis o comanda noua.

## 3. Intreruperi si sincronizare

### 28. Ce este `Flag_CDA`?
`Flag_CDA` este un flag software care marcheaza aparitia unei comenzi noi de la ARM.

### 29. Cine seteaza `Flag_CDA`?
Intreruperea `IRQ2` seteaza `Flag_CDA = 1`.

### 30. De ce `IRQ2` doar seteaza un flag?
Pentru ca ISR-ul de comanda trebuie sa fie foarte scurt. Decodarea se face ulterior in fluxul audio, in `input_samples`.

### 31. Unde se reseteaza `Flag_CDA`?
Dupa citirea si decodarea comenzii, codul scrie `0` in `Flag_CDA`.

### 32. Ce face intreruperea `SPORT0 RX`?
Ea apeleaza rutina `input_samples`, adica locul unde se proceseaza fiecare cadru audio primit de la CODEC.

### 33. De ce este bine ca procesarea sa fie in `SPORT0 RX`?
Pentru ca algoritmii se executa sincron cu esantioanele audio. Fiecare cadru primit poate fi procesat imediat.

### 34. Ce se intampla in bucla principala `wt`?
DSP-ul sta intr-o bucla infinita cu `nop` si `jump wt`. Lucrul real se face din intreruperi.

### 35. De ce programul principal nu proceseaza audio direct?
Pentru ca momentul corect de procesare este determinat de primirea esantioanelor prin `SPORT0`, nu de o bucla software libera.

### 36. Ce inseamna `imask = 0x220`?
Este masca de activare a intreruperilor utile in codul activ. Ea permite intreruperile necesare pentru comenzi si pentru receptia audio.

### 37. Ce este tabela vectorilor de intrerupere?
Este zona din memoria de program unde fiecare sursa de intrerupere are o adresa fixa si un cod scurt de salt sau tratare.

### 38. Ce face vectorul de reset?
Vectorul de reset sare la eticheta `start`, unde se initializeaza DSP-ul.

### 39. Ce face vectorul pentru comanda de la ARM?
Seteaza `Flag_CDA = 1`, apoi revine din intrerupere cu `rti`.

### 40. Ce face vectorul pentru `SPORT0 RX`?
Sare la `input_samples`, unde se citeste comanda daca exista si se proceseaza esantionul audio.

## 4. SPORT0, CODEC si buffere

### 41. Ce este `SPORT0`?
`SPORT0` este portul serial al DSP-ului folosit pentru comunicatia cu CODEC-ul AD1847.

### 42. Ce este autobuffering?
Autobuffering inseamna ca transferul dintre `SPORT0` si bufferele din memorie se face automat, cu pointeri si lungimi configurate.

### 43. Ce contine `rx_buf`?
`rx_buf[0]` contine status/control CODEC, `rx_buf[1]` contine esantionul stang si `rx_buf[2]` contine esantionul drept.

### 44. Ce contine `tx_buf`?
`tx_buf[0]` contine cuvantul de control catre CODEC, `tx_buf[1]` iesirea pentru canalul stang si `tx_buf[2]` iesirea pentru canalul drept.

### 45. De ce au bufferele lungime 3?
Pentru ca fiecare cadru are un cuvant de control/status si doua cuvinte audio, unul pentru stanga si unul pentru dreapta.

### 46. Ce rol au `i5` si `l5`?
Ele configureaza pointerul si lungimea bufferului de receptie `rx_buf`.

### 47. Ce rol au `i6` si `l6`?
Ele configureaza pointerul si lungimea bufferului de transmisie `tx_buf`.

### 48. Ce face `read_buff`?
Citeste esantionul de intrare de pe canalul selectat: `rx_buf+1` pentru stanga sau `rx_buf+2` pentru dreapta.

### 49. Ce face `write_out`?
Scrie rezultatul prelucrarii in canalul selectat: `tx_buf+1` pentru stanga sau `tx_buf+2` pentru dreapta.

### 50. Codul activ copiaza explicit canalul neprocesat?
Nu. In codul activ, `write_out` scrie doar canalul selectat. Daca se cere bypass explicit pe celalalt canal, codul ar trebui completat sa copieze si canalul neprocesat.

### 51. Ce sunt `init_cmds`?
Sunt cele 13 cuvinte de initializare pentru CODEC-ul AD1847.

### 52. Exista o observatie importanta despre initializarea CODEC-ului?
Da. In codul activ exista un `jump skip` inainte de secventa activa de initializare CODEC. Asta inseamna ca acea secventa este sarita in varianta curenta.

### 53. De ce poate fi problematic `jump skip`?
Daca hardware-ul real are nevoie de trimiterea comenzilor de initializare catre CODEC, sarirea secventei poate impiedica pornirea corecta a audio.

### 54. Ce este `stat_flag`?
Este un flag folosit in secventa de initializare CODEC pentru a marca daca mai sunt comenzi de transmis.

### 55. Ce face rutina `next_cmd`?
Trimite urmatoarea comanda de initializare din `init_cmds` catre `tx_buf`, apoi opreste `stat_flag` cand secventa s-a terminat.

## 5. Organizarea memoriei pe DSP

### 56. Ce inseamna `DM`?
`DM` inseamna Data Memory, memoria folosita pentru variabile, buffere si linii de intarziere.

### 57. Ce inseamna `PM`?
`PM` inseamna Program Memory, memoria folosita pentru cod si, in unele cazuri, pentru coeficienti accesati in paralel.

### 58. De ce se pune `hh` in `PM`?
Coeficientii filtrului ALE sunt in `PM` pentru a permite acces paralel la date si coeficienti, folosind arhitectura Harvard.

### 59. Ce este arhitectura Harvard?
Este o arhitectura cu memorii si magistrale separate pentru program si date, permitand acces simultan la instructiuni si operanzi.

### 60. Ce sunt bufferele circulare?
Sunt zone de memorie unde pointerul revine automat la inceput dupa ce ajunge la capat, utile pentru linii de intarziere si ferestre de esantioane.

### 61. Unde se folosesc buffere circulare?
In `delay_agc`, `delay_mf`, `fir_d`, `input_ale` si `hh`.

### 62. De ce sunt utile bufferele circulare in DSP?
Pentru ca multe algoritme de semnal folosesc ultimele N esantioane, iar bufferele circulare evita mutarea manuala a datelor.

### 63. Ce sunt registrele `i`, `m` si `l`?
Sunt registre de adresare. `i` este pointerul, `m` este pasul de incrementare/decrementare, iar `l` este lungimea bufferului circular.

### 64. Ce este `cntr`?
Este registrul folosit pentru bucle hardware de tip `do ... until ce`.

### 65. De ce sunt utile buclele hardware?
Ele reduc overhead-ul buclelor software si sunt eficiente pentru procesare repetitiva pe DSP.

## 6. Rutina `input_samples`

### 66. Ce face `input_samples` la inceput?
Activeaza registrii secundari cu `ena sec_reg`, apoi verifica `Flag_CDA`.

### 67. Ce se intampla daca `Flag_CDA = 0`?
Nu exista comanda noua, deci codul citeste esantionul curent si sare la rutarea catre algoritmul deja selectat.

### 68. Ce se intampla daca `Flag_CDA != 0`?
Codul citeste comanda din `Prog_Flag_Data`, o valideaza, extrage ID-ul, canalul si algoritmul, apoi reseteaza flag-ul.

### 69. De ce se salveaza esantionul in `temp_in`?
Pentru ca algoritmii sa lucreze cu o variabila comuna, indiferent daca esantionul a venit de pe canalul stang sau drept.

### 70. Ce este `cda_prev`?
Este algoritmul anterior. Daca algoritmul curent difera de cel anterior, codul reinitializeaza starile filtrelor.

### 71. De ce se reinitializeaza filtrele cand se schimba algoritmul?
Pentru ca fiecare algoritm are stare interna proprie. Fara resetare, date vechi dintr-un algoritm ar putea afecta rezultatul altui algoritm.

### 72. Ce se intampla daca algoritmul ramane acelasi?
Se pastreaza starea interna a algoritmului, ceea ce este important pentru adaptare si pentru continuitatea procesarii.

### 73. Cum se face rutarea catre algoritm?
Variabila `cda` este comparata cu `0`, `1` si `2`. In functie de rezultat, se sare la `run_agc`, `run_ale` sau `run_mf`.

### 74. Ce valoare produce bypass?
Orice valoare care nu este `0`, `1` sau `2` cade in `invalid_cmd`, unde intrarea este scrisa direct la iesire.

## 7. AGC - Automatic Gain Control

### 75. Ce inseamna AGC?
AGC inseamna Automatic Gain Control, adica reglarea automata a castigului pentru a mentine nivelul semnalului aproape de o referinta.

### 76. Care este formula principala pentru iesirea AGC?
Formula este `y(n) = g(n-1) * x(n)`, unde `g` este castigul anterior.

### 77. Cum se actualizeaza castigul?
Castigul se actualizeaza pe baza erorii dintre referinta si nivelul mediu estimat al iesirii: `g(n) = g(n-1) + mu * (ref - S)`.

### 78. Ce reprezinta `S_agc`?
`S_agc` reprezinta estimarea nivelului mediu al iesirii, calculata din valorile absolute recente.

### 79. Ce reprezinta `ref_agc`?
`ref_agc` este nivelul tinta catre care AGC incearca sa aduca amplitudinea iesirii.

### 80. Ce reprezinta `mu_agc`?
`mu_agc` este pasul de adaptare. El controleaza viteza cu care se modifica castigul.

### 81. Ce se intampla daca `mu` este prea mare?
AGC reactioneaza rapid, dar poate oscila sau deveni instabil.

### 82. Ce se intampla daca `mu` este prea mic?
AGC devine stabil, dar raspunde lent la schimbari de amplitudine.

### 83. De ce se foloseste `abs` in AGC?
Pentru ca se estimeaza amplitudinea semnalului, iar amplitudinea nu trebuie sa depinda de semnul esantionului.

### 84. De ce exista `g_int_agc` si `g_fr_agc`?
Castigul este tinut in doua parti pentru a permite o reprezentare mai flexibila in aritmetica fractionara a DSP-ului.

### 85. Ce face `agc_init`?
Reseteaza starea AGC, pune `S_agc`, castigul si pointerii la valori initiale si seteaza `ref_agc = 0.5` si `mu_agc = 0.05`.

### 86. Ce limitare are AGC in codul activ?
Parametrii sunt fixi in codul activ. Documentatia vorbeste despre parametri din switch-uri, dar fisierul ASM activ nu citeste `SW7..SW0`.

### 87. Cand este util AGC?
Cand nivelul semnalului de intrare variaza si vrem o iesire cu amplitudine mai constanta.

## 8. ALE - Adaptive Line Enhancer

### 88. Ce inseamna ALE?
ALE inseamna Adaptive Line Enhancer, un filtru adaptiv folosit pentru extragerea componentei predictibile sau periodice a unui semnal.

### 89. Care este ideea principala a ALE?
Se foloseste o versiune intarziata a semnalului ca intrare pentru un filtru FIR adaptiv, iar coeficientii se modifica in functie de eroarea de predictie.

### 90. Ce reprezinta `N_ALE`?
`N_ALE` este numarul de coeficienti ai filtrului adaptiv, in codul activ fiind `256`.

### 91. Ce reprezinta `D_ALE`?
`D_ALE` este intarzierea folosita in linia de intarziere ALE, in codul activ fiind `128`.

### 92. Ce reprezinta `input_ale`?
Este bufferul circular care realizeaza intarzierea semnalului de intrare.

### 93. Ce reprezinta `fir_d`?
Este linia de intarziere folosita de filtrul FIR adaptiv.

### 94. Ce reprezinta `hh`?
Este vectorul de coeficienti ai filtrului FIR adaptiv, stocat in Program Memory.

### 95. Ce face subrutina `fir`?
Calculeaza suma produselor dintre esantioanele intarziate si coeficientii filtrului: `y(n) = suma x(k) * h(k)`.

### 96. Ce face subrutina `llms`?
Actualizeaza coeficientii filtrului folosind o regula de tip Leaky LMS.

### 97. Ce inseamna LMS?
LMS inseamna Least Mean Squares, o metoda adaptiva care modifica coeficientii pentru a reduce eroarea medie patrata.

### 98. Ce inseamna Leaky LMS?
Este o varianta LMS cu factor de scurgere, care impiedica valorile coeficientilor sa creasca necontrolat.

### 99. Ce reprezinta `mu_ale`?
Este pasul de adaptare al filtrului ALE.

### 100. Ce reprezinta `lambda_ale`?
Este factorul de scurgere folosit in Leaky LMS pentru stabilitate.

### 101. Ce se intampla daca `mu_ale` este prea mare?
Filtrul se adapteaza rapid, dar poate deveni instabil.

### 102. Ce se intampla daca `mu_ale` este prea mic?
Filtrul se adapteaza lent si poate avea nevoie de multe esantioane pentru convergenta.

### 103. Ce face `ale_init`?
Seteaza `mu_ale` si `lambda_ale`, initializeaza pointerii pentru bufferele circulare si pune coeficientii si liniile de intarziere la zero.

### 104. Cand este util ALE?
Cand semnalul util are componente corelate sau periodice, iar zgomotul este mai putin corelat in timp.

## 9. MF - Median Filter

### 105. Ce inseamna MF?
MF inseamna Median Filter, adica filtru median.

### 106. Care este scopul filtrului median?
Sa elimine zgomotul impulsiv, adica spike-uri sau valori izolate foarte mari/mici.

### 107. Cum functioneaza MF?
Pastreaza o fereastra de esantioane, o copiaza intr-un buffer liniar, sorteaza valorile si alege elementul median.

### 108. Ce reprezinta `W_MF`?
`W_MF` este dimensiunea ferestrei mediane. In codul activ, `W_MF = 3`.

### 109. Ce reprezinta `K_MF`?
`K_MF` este indexul elementului median. In codul activ, `K_MF = 1`, adica elementul din mijloc pentru o fereastra de 3 valori.

### 110. Ce contine `delay_mf`?
Este bufferul circular cu ultimele esantioane folosite de filtrul median.

### 111. Ce contine `delay_sorted`?
Este copia liniara a ferestrei, folosita pentru sortare.

### 112. Ce metoda de sortare foloseste codul?
Codul foloseste sortare prin selectie in subrutina `sort_sel`.

### 113. De ce se copiaza fereastra inainte de sortare?
Pentru ca sortarea modifica ordinea datelor. Bufferul circular trebuie pastrat ca istoric al esantioanelor.

### 114. De ce filtrul median elimina spike-uri?
Pentru ca o valoare extrema izolata ajunge la capatul sirului sortat, nu in centru.

### 115. Ce dezavantaj are filtrul median?
Are cost computational mai mare decat un filtru liniar simplu, deoarece necesita sortare.

### 116. Ce face `mf_init`?
Initializeaza pointerii ferestrei mediane si reseteaza flag-ul de initializare.

### 117. Ce diferenta exista intre documentatie si cod la MF?
Documentatia mentioneaza uneori `K=3` si `W=6`, dar codul activ foloseste `K_MF=1` si `W_MF=3`.

## 10. STM32, privit din perspectiva DSP

### 118. Ce trebuie sa livreze STM32 catre DSP?
Un octet stabil pe magistrala `PCDA7..PCDA0`, cu formatul asteptat de DSP.

### 119. De ce STM32 afiseaza aceeasi comanda pe LED-uri?
Pentru verificare vizuala. LED-urile arata ce comanda a fost transmisa catre DSP.

### 120. Ce rol are butonul `PRG`?
Este trigger-ul utilizatorului pentru transmiterea comenzii de pe STM32.

### 121. Ce rol are butonul `IA` pe partea DSP?
Semnalizeaza DSP-ului ca trebuie sa citeasca o comanda noua. In codul activ, acest eveniment ajunge prin `IRQ2`.

### 122. De ce exista doua actiuni, `PRG` si `IA`?
`PRG` pune comanda pe magistrala din partea STM32, iar `IA` spune DSP-ului cand sa o preia.

### 123. Ce se poate intampla daca `IA` este apasat inainte ca STM32 sa puna comanda corecta?
DSP-ul poate citi o valoare veche sau invalida de pe magistrala.

### 124. De ce este important ca semnalul de comanda sa fie stabil?
Pentru ca DSP-ul citeste direct bitii de pe port. Daca valorile se schimba in timpul citirii, comanda poate fi interpretata gresit.

### 125. Ce face masina de stari de pe STM32?
Evita transmiterea repetata a aceleiasi comenzi cat timp butonul este tinut apasat si separa asteptarea eliberarii de asteptarea apasarii.

### 126. Ce rol are `TIM2` pe STM32?
`TIM2` genereaza o baza de timp periodica pentru esantionarea butoanelor si actualizarea masinii de stari.

### 127. STM32 proceseaza semnal audio?
Nu. Procesarea audio este facuta de DSP.

## 11. Simulare, testare si validare

### 128. Ce poate fi testat fara hardware?
Se poate testa logica STM32 pe PC, se pot verifica maparile de comenzi si se pot rula simulari DSP in VisualDSP daca exista toolchain/licenta.

### 129. Ce nu poate fi complet verificat fara hardware?
Nu pot fi verificate complet comportamentul electric real, CODEC-ul, cablarea `PCDA -> PF`, timing-ul real si calitatea audio la iesire.

### 130. Ce fisier contine un simulator simplu pentru logica STM32?
`pc_tests/stm32_logic_sim.c` contine teste PC-only pentru masina de stari STM32.

### 131. Ce verifica simulatorul STM32?
Verifica faptul ca o comanda este transmisa o singura data la o apasare valida si ca valorile apar pe LED si PCDA.

### 132. Ce problema a indicat scriptul `check_whole_project.ps1` pe codul activ?
Scriptul asteapta simboluri de simulator DSP care exista in alta varianta a proiectului, dar nu in fisierul ASM activ.

### 133. Ce inseamna daca `test_ext.dxe` este mai vechi decat `test_ext.asm`?
Inseamna ca binarul incarcat in VisualDSP poate sa nu corespunda sursei ASM curente si trebuie refacut build-ul.

### 134. De ce e important build-ul dupa modificari?
Pentru ca modificarile din ASM nu ajung pe DSP pana cand proiectul nu este reasamblat si incarcat din nou.

### 135. Ce ar trebui verificat in VisualDSP?
Ca proiectul se asambleaza fara erori, ca vectorii de intrerupere sunt corecti, ca `input_samples` este apelat si ca `tx_buf` primeste valorile asteptate.

### 136. Ce ar trebui verificat pe hardware?
Comanda pe LED-uri, semnalul pe PCDA, declansarea `IRQ2`, activitatea SPORT0, initializarea CODEC si audio la iesire.

## 12. Intrebari capcana si raspunsuri bune

### 137. Documentatia spune ca parametrii vin de pe `SW7..SW0`. Codul activ face asta?
Nu. Codul activ are parametrii fixati prin constante si valori initiale. Daca se cere strict parametrizare din switch-uri, codul trebuie extins sau trebuie folosita varianta care contine citire `PORT_IN`.

### 138. Documentatia spune `IRQL0`, iar codul activ spune `IRQ2`. Care este corect?
Pentru fisierul ASM activ este `IRQ2`. La sustinere trebuie explicat conform conexiunii reale folosite pe placa.

### 139. Documentatia spune ca iesirea este scrisa pe ambele canale. Codul activ face asta?
Nu complet. `write_out` scrie doar canalul selectat. Celalalt canal nu este copiat explicit in aceasta rutina.

### 140. Comentariile din ASM sunt scrise cu `/ *` si `* /`. Este ok?
Trebuie verificat in assembler. Comentariul C corect este `/* ... */`, fara spatii intre caractere. Daca assemblerul nu accepta forma cu spatiu, apar erori de sintaxa.

### 141. De ce exista `jump skip` inainte de initializarea CODEC?
Este pastrat din fluxul descris in document, dar practic sare peste secventa activa de initializare. Daca se testeaza pe hardware real, trebuie verificat daca aceasta sarire este acceptabila.

### 142. Daca algoritmul este schimbat din AGC in ALE, ce se intampla cu starile interne?
Codul seteaza flag-urile de initializare pentru toate filtrele, iar algoritmul apelat isi reseteaza starea proprie.

### 143. De ce nu este bine sa pastrezi starile interne intre algoritmi diferiti?
Pentru ca fiecare algoritm interpreteaza memoria si pointerii diferit, iar datele vechi pot produce iesiri gresite.

### 144. Ce inseamna saturarea in calculele DSP?
Saturarea limiteaza rezultatul la intervalul numeric disponibil, evitand overflow-ul care ar intoarce valoarea intr-un semn gresit.

### 145. De ce se foloseste aritmetica fractionara?
Semnalele audio si coeficientii sunt reprezentati eficient ca valori fractionare, potrivite pentru operatii DSP pe 16 biti.

### 146. Ce este o operatie MAC?
MAC inseamna multiply-accumulate: inmultire urmata de acumulare. Este operatia de baza pentru FIR, LMS si multe calcule DSP.

### 147. De ce ADSP-2181 este potrivit pentru FIR?
Pentru ca are unitate MAC, buffere circulare si acces simultan la date si coeficienti prin arhitectura Harvard.

### 148. Ce se intampla daca algoritmul selectat dureaza prea mult?
DSP-ul poate rata urmatorul cadru audio, ceea ce duce la distorsiuni, drop-uri sau comportament instabil in timp real.

### 149. Care algoritm este cel mai costisitor?
ALE este de obicei cel mai costisitor, deoarece are FIR cu `N_ALE=256` si actualizare adaptiva a coeficientilor.

### 150. Care algoritm este cel mai simplu?
Bypass este cel mai simplu, apoi MF cu fereastra mica sau AGC cu `M_AGC=4`, in functie de implementare.

## 13. Raspunsuri scurte de retinut

### 151. Cum explici proiectul in 20 de secunde?
STM32 construieste si transmite o comanda pe 8 biti, iar DSP-ul o decodeaza si aplica in timp real unul dintre algoritmii `AGC`, `ALE` sau `MF` pe canalul audio selectat.

### 152. Cum explici partea DSP intr-o fraza?
DSP-ul primeste esantioane prin `SPORT0`, citeste comenzi prin `Prog_Flag_Data`, valideaza comanda si proceseaza audio in rutina `input_samples`.

### 153. Cum explici AGC intr-o fraza?
AGC modifica automat castigul pentru ca amplitudinea iesirii sa ramana aproape de o referinta.

### 154. Cum explici ALE intr-o fraza?
ALE foloseste un filtru adaptiv pentru a extrage componentele predictibile ale semnalului si pentru a reduce componentele mai putin corelate.

### 155. Cum explici MF intr-o fraza?
MF sorteaza o fereastra de esantioane si alege mediana, eliminand bine spike-urile.

### 156. Cum explici `Flag_CDA` intr-o fraza?
`Flag_CDA` spune rutinei audio ca exista o comanda noua de citit de la ARM.

### 157. Cum explici selectia canalului intr-o fraza?
Bitul `D3` decide daca DSP-ul citeste si scrie canalul stang sau drept.

### 158. Cum explici validarea comenzii intr-o fraza?
DSP-ul accepta comanda doar daca `D7-D6=11` si ID-ul din `D2-D0` este `001`.

### 159. Cum explici rolul SPORT0 intr-o fraza?
`SPORT0` este interfata seriala prin care DSP-ul schimba cadre audio cu CODEC-ul AD1847.

### 160. Cum explici de ce sunt folosite intreruperi?
Intreruperile permit sincronizarea cu evenimente reale: comanda noua de la ARM si esantion audio nou de la CODEC.

## 14. Lista rapida de lucruri de invatat

1. Formatul comenzii: `D7-D6` validare, `D5-D4` algoritm, `D3` canal, `D2-D0` ID.
2. Exemplele `0xC1`, `0xD1`, `0xE1`, `0xC9`, `0xD9`, `0xE9`.
3. Rolul `Flag_CDA` si al lui `IRQ2`.
4. Rolul `SPORT0 RX` si al rutinei `input_samples`.
5. Structura `rx_buf` si `tx_buf`.
6. Diferenta dintre `DM` si `PM`.
7. De ce se folosesc buffere circulare.
8. Formula de baza pentru AGC.
9. Ideea de FIR adaptiv si LLMS la ALE.
10. Ideea de sortare si mediana la MF.
11. Diferentele dintre documentatie si codul activ.
12. Limitarea produsa de `jump skip` la initializarea CODEC.
13. Faptul ca fisierul activ nu citeste `SW7..SW0`.
14. Faptul ca `write_out` scrie doar canalul selectat.
15. Faptul ca build-ul trebuie refacut dupa modificarea ASM-ului.
