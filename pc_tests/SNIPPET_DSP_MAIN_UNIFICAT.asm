/*
 * SNIPPET DSP MAIN UNIFICAT
 *
 * Acest fisier este pentru documentatie si explicatii.
 * Nu este folosit la build. Codul real ramane in:
 * DSP test/DSP test/test_ext/test_ext.asm
 *
 * Comparatie intre 05-1 si 15-1:
 *
 * 05-1:
 * - foloseste Flag_CDA si doua stari in input_samples:
 *   starea_1 = citire comanda
 *   starea_2 = validare + selectie functie
 * - functiile AGC / ALE / MF sunt doar bypass
 * - ID-ul functiei este extras din D2..D0
 *
 * 15-1:
 * - pastreaza aceeasi idee de baza: IRQ de comanda + SPORT0 RX
 * - adauga campuri separate pentru functie, canal si parametru
 * - ramane la nivel de schelet, cu TODO pentru AGC / ALE / MF
 *
 * test_ext.asm:
 * - pastreaza structura buna din 05-1 / 15-1
 * - inlocuieste TODO-urile cu algoritmi reali AGC / ALE / MF
 * - adauga parametrizarea din SW7..SW0
 * - adauga selectie de canal stanga / dreapta
 */

#define MODE_AGC        0
#define MODE_ALE        1
#define MODE_MF         2
#define MODE_BYPASS     3

#define CMD_VALID_MASK   0x00C0
#define CMD_VALID_BITS   0x00C0
#define CMD_ID_MASK      0x0007
#define CMD_CHANNEL_MASK 0x0008

/*
 * Variabilele de mai jos sunt cele importante pentru logica DSP:
 * - flag_cda: spune daca exista o comanda noua
 * - current_command: ultimul octet primit de la ARM
 * - current_switches: ultimii parametri cititi din SW7..SW0
 * - current_mode: AGC / ALE / MF / bypass
 * - current_channel: 0 = stanga, 1 = dreapta
 */

.var    flag_cda = 0;
.var    current_command = 0x0000;
.var    current_switches = 0x0000;
.var    current_mode = MODE_BYPASS;
.var    current_channel = 0x0000;

.var    sample_left = 0x0000;
.var    sample_right = 0x0000;
.var    selected_input = 0x0000;
.var    selected_output = 0x0000;

/*
 * IRQ2 nu proceseaza semnalul audio.
 * El doar semnalizeaza ca ARM a pus o comanda noua pe magistrala CDA.
 */
cmd_interrupt:
        ax0 = 1;
        dm(flag_cda) = ax0;
        rti;

/*
 * input_samples este rutina principala de lucru.
 * Ea se executa la fiecare esantion audio primit de la codec prin SPORT0.
 */
input_samples:
        ena sec_reg;

        ax0 = dm(rx_buf + 1);
        dm(sample_left) = ax0;
        ax0 = dm(rx_buf + 2);
        dm(sample_right) = ax0;

        ax0 = dm(flag_cda);
        ar = pass ax0;
        if eq jump process_sample;

        /*
         * Daca exista comanda noua:
         * - se decodeaza comanda de pe PF7..PF0
         * - se citesc si switch-urile SW7..SW0
         * - se configureaza modul curent
         * - semnalul curent este lasat nemodificat in acest cadru
         */
        call latch_command;
        ax0 = 0;
        dm(flag_cda) = ax0;
        ax0 = dm(sample_left);
        dm(tx_buf + 1) = ax0;
        ax0 = dm(sample_right);
        dm(tx_buf + 2) = ax0;
        dis sec_reg;
        rti;

process_sample:
        /*
         * Se alege canalul pe care aplicam prelucrarea.
         * Celalalt canal trece mai departe neschimbat.
         */
        ax0 = dm(current_mode);
        ay0 = MODE_BYPASS;
        ar = ax0 - ay0;
        if eq jump bypass_output;

        ax0 = dm(current_channel);
        ar = pass ax0;
        if eq jump select_left_input;
        ax0 = dm(sample_right);
        dm(selected_input) = ax0;
        jump dispatch_mode;

select_left_input:
        ax0 = dm(sample_left);
        dm(selected_input) = ax0;

dispatch_mode:
        /*
         * Aici se vede unificarea reala a celor 3 exemple:
         * - AGC
         * - ALE
         * - MF
         */
        ax0 = dm(current_mode);
        ay0 = MODE_AGC;
        ar = ax0 - ay0;
        if eq jump run_agc;
        ay0 = MODE_ALE;
        ar = ax0 - ay0;
        if eq jump run_ale;
        ay0 = MODE_MF;
        ar = ax0 - ay0;
        if eq jump run_mf;
        jump bypass_output;

run_agc:
        call process_agc;
        jump write_processed_output;

run_ale:
        call process_ale;
        jump write_processed_output;

run_mf:
        call process_mf;
        jump write_processed_output;

bypass_output:
        ax0 = dm(sample_left);
        dm(tx_buf + 1) = ax0;
        ax0 = dm(sample_right);
        dm(tx_buf + 2) = ax0;
        dis sec_reg;
        rti;

write_processed_output:
        ax0 = dm(current_channel);
        ar = pass ax0;
        if eq jump write_left_processed;
        ax0 = dm(sample_left);
        dm(tx_buf + 1) = ax0;
        ax0 = dm(selected_output);
        dm(tx_buf + 2) = ax0;
        dis sec_reg;
        rti;

write_left_processed:
        ax0 = dm(selected_output);
        dm(tx_buf + 1) = ax0;
        ax0 = dm(sample_right);
        dm(tx_buf + 2) = ax0;
        dis sec_reg;
        rti;

/*
 * latch_command este partea care continua ideea din 05-1 si 15-1,
 * dar o duce pana la capat:
 * - citeste comanda
 * - citeste switch-urile
 * - extrage canalul
 * - valideaza comanda
 * - configureaza AGC / ALE / MF
 */
latch_command:
        ax0 = dm(Prog_Flag_Data);
        ay0 = 0x00FF;
        ar = ax0 and ay0;
        ax0 = ar;
        dm(current_command) = ax0;

        si = IO(PORT_IN);
        ax0 = si;
        ay0 = 0x00FF;
        ar = ax0 and ay0;
        ax0 = ar;
        dm(current_switches) = ax0;

        ax0 = dm(current_command);
        ay0 = CMD_CHANNEL_MASK;
        ar = ax0 and ay0;
        if eq jump cmd_left_channel;
        ax0 = 1;
        dm(current_channel) = ax0;
        jump validate_command;

cmd_left_channel:
        ax0 = 0;
        dm(current_channel) = ax0;

validate_command:
        ax0 = dm(current_command);
        ay0 = CMD_VALID_MASK;
        ar = ax0 and ay0;
        ay0 = CMD_VALID_BITS;
        af = ar - ay0;
        if ne jump set_bypass_mode;

        ax0 = dm(current_command);
        ay0 = CMD_ID_MASK;
        ar = ax0 and ay0;
        ay0 = 3;
        af = ar - ay0;
        if ge jump set_bypass_mode;

        ax0 = dm(current_command);
        ay0 = CMD_ID_MASK;
        ar = ax0 and ay0;
        dm(current_mode) = ar;

        ax0 = dm(current_mode);
        ay0 = MODE_AGC;
        ar = ax0 - ay0;
        if eq jump cfg_agc_mode;
        ay0 = MODE_ALE;
        ar = ax0 - ay0;
        if eq jump cfg_ale_mode;
        ay0 = MODE_MF;
        ar = ax0 - ay0;
        if eq jump cfg_mf_mode;

set_bypass_mode:
        ax0 = MODE_BYPASS;
        dm(current_mode) = ax0;
        call update_display;
        rts;

cfg_agc_mode:
        call configure_agc;
        call update_display;
        rts;

cfg_ale_mode:
        call configure_ale;
        call update_display;
        rts;

cfg_mf_mode:
        call configure_mf;
        call update_display;
        rts;

/*
 * Parametrii sunt configurati din switch-uri:
 * - AGC: REF, M, mu
 * - ALE: D, a, mu, lambda
 * - MF: K
 */
configure_agc:
        /* codul real este in test_ext.asm */
        rts;

configure_ale:
        /* codul real este in test_ext.asm */
        rts;

configure_mf:
        /* codul real este in test_ext.asm */
        rts;

/*
 * Functiile de mai jos sunt algoritmii propriu-zisi.
 * Ele reprezinta extinderea fata de 05-1 si 15-1, unde existau doar TODO-uri.
 */
process_agc:
        /* vezi implementarea completa in test_ext.asm */
        rts;

process_ale:
        /* vezi implementarea completa in test_ext.asm */
        rts;

process_mf:
        /* vezi implementarea completa in test_ext.asm */
        rts;

