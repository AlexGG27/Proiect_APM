#include "def2181.h"

#define PORT_OUT    0xFF
#define PORT_IN     0x1FF


.SECTION/DM buf_var1;
.var    rx_buf[3];

.SECTION/DM buf_var2;
.var    tx_buf[3] = 0xc000, 0x0000, 0x0000;

.SECTION/DM buf_var3;
.var    init_cmds[13] =
        0xc002,
        0xc102,
        0xc288,
        0xc388,
        0xc488,
        0xc588,
        0xc680,
        0xc780,
        0xc85c,
        0xc909,
        0xca00,
        0xcc40,
        0xcd00;


.SECTION/DM data1;
.var    stat_flag;
.var    PF_input;
.var    PF_output;
.var    Flag_CDA;
.var    cmd_comanda;
.var    cmd_corect;
.var    id_functie;
.var    x_in;
.var    y_out;


.SECTION/PM pm_da;

/* intreruperi */
.SECTION/PM interrupts;
        jump start;              rti; rti; rti;     /* 00: reset */
        rti;                     rti; rti; rti;     /* 04: IRQ2 */
        rti;                     rti; rti; rti;     /* 08: IRQL1 */
        rti;                     rti; rti; rti;     /* 0C: IRQL0 */

        ar = dm(stat_flag);                          /* 10: SPORT0 tx */
        ar = pass ar;
        if eq rti;
        jump next_cmd;

        jump input_samples;                          /* 14: SPORT0 rx */
        rti;                     rti; rti;

        jump isr_ia;             rti; rti; rti;     /* 18: IRQE */
        rti;                     rti; rti; rti;     /* 1C: BDMA */
        rti;                     rti; rti; rti;     /* 20: SPORT1 tx or IRQ1 */
        rti;                     rti; rti; rti;     /* 24: SPORT1 rx or IRQ0 */
        nop;                     rti; rti; rti;     /* 28: timer */
        rti;                     rti; rti; rti;     /* 2C: power down */


.SECTION/PM seg_code;

start:
        /* shut down sport 0 */
        ax0 = b#0000100000000000;
        dm(Sys_Ctrl_Reg) = ax0;

        ena timer;

        i5 = rx_buf;
        l5 = LENGTH(rx_buf);
        i6 = tx_buf;
        l6 = LENGTH(tx_buf);
        i3 = init_cmds;
        l3 = LENGTH(init_cmds);

        m1 = 1;
        m5 = 1;

        ax0 = 0;
        dm(Flag_CDA) = ax0;
        dm(cmd_comanda) = ax0;
        dm(cmd_corect) = ax0;
        dm(id_functie) = ax0;
        dm(x_in) = ax0;
        dm(y_out) = ax0;

        /* SPORT0 CONFIG */
        ax0 = b#0000110011010111;
        dm(Sport0_Autobuf_Ctrl) = ax0;

        ax0 = 0;
        dm(Sport0_Rfsdiv) = ax0;

        ax0 = 0;
        dm(Sport0_Sclkdiv) = ax0;

        ax0 = b#1000011000001111;
        dm(Sport0_Ctrl_Reg) = ax0;

        ax0 = b#0000000000000111;
        dm(Sport0_Tx_Words0) = ax0;

        ax0 = b#0000000000000111;
        dm(Sport0_Tx_Words1) = ax0;

        ax0 = b#0000000000000111;
        dm(Sport0_Rx_Words0) = ax0;

        ax0 = b#0000000000000111;
        dm(Sport0_Rx_Words1) = ax0;

        /* SYSTEM CONFIG */
        ax0 = b#0001100000000000;
        dm(Sys_Ctrl_Reg) = ax0;

        ifc = b#00000011111110;
        nop;

        icntl = b#00010;
        mstat = b#1100000;

        /******************************
         ADSP 1847 Codec intialization
        *******************************/
        ax0 = 1;
        dm(stat_flag) = ax0;

        ena ints;
        imask = b#0001010001;

        ax0 = dm(i6, m5);
        tx0 = ax0;

check_init:
        ax0 = dm(stat_flag);
        af = pass ax0;
        if ne jump check_init;

        ay0 = 2;

check_aci1:
        ax0 = dm(rx_buf);
        ar = ax0 and ay0;
        if eq jump check_aci1;

check_aci2:
        ax0 = dm(rx_buf);
        ar = ax0 and ay0;
        if ne jump check_aci2;

        idle;

        ay0 = 0xbf3f;
        ax0 = dm(init_cmds + 6);
        ar = ax0 and ay0;
        dm(tx_buf) = ar;
        idle;

        ax0 = dm(init_cmds + 7);
        ar = ax0 and ay0;
        dm(tx_buf) = ar;
        idle;

        ifc = b#00000011111110;
        nop;

        imask = b#0001100001;

        /* wait states */
        si = 0xFFFF;
        dm(Dm_Wait_Reg) = si;

        /* PF ports */
        si = 0x0000;
        dm(Prog_Flag_Comp_Sel_Ctrl) = si;

wt:
        idle;
        jump wt;


isr_ia:
        ena sec_reg;
        ax0 = 1;
        dm(Flag_CDA) = ax0;
        rti;


input_samples:
        ena sec_reg;

        mr1 = dm(rx_buf + 1);
        dm(x_in) = mr1;

        ax0 = dm(Flag_CDA);
        ar = pass ax0;
        if ne jump starea_1;
        jump starea_2;


starea_1:
        ax0 = dm(Prog_Flag_Data);
        dm(cmd_comanda) = ax0;
        dm(PF_input) = ax0;

        ax0 = 0;
        dm(Flag_CDA) = ax0;
        rti;


starea_2:
        ax0 = dm(cmd_comanda);
        ay0 = 0x00C0;
        ar = ax0 and ay0;
        af = ar - ay0;
        if ne jump cmd_invalida;

        ax0 = 1;
        dm(cmd_corect) = ax0;

        ax0 = dm(cmd_comanda);
        ay0 = 0x0007;
        ar = ax0 and ay0;
        dm(id_functie) = ar;

        ax0 = dm(id_functie);

        ay0 = 0;
        ar = ax0 - ay0;
        if eq jump agc_func;

        ay0 = 1;
        ar = ax0 - ay0;
        if eq jump ale_func;

        ay0 = 2;
        ar = ax0 - ay0;
        if eq jump mf_func;

        jump bypass;


cmd_invalida:
        ax0 = 0;
        dm(cmd_corect) = ax0;
        jump bypass;


/* cele 3 functii de mai jos se vor implementa in etapa a II-a */
agc_func:
        jump bypass;

ale_func:
        jump bypass;

mf_func:
        jump bypass;


bypass:
        mr1 = dm(x_in);
        dm(y_out) = mr1;
        jump output;


output:
        dm(tx_buf + 1) = mr1;       /* canal stanga */
        dm(tx_buf + 2) = mr1;       /* canal dreapta */
        rti;


next_cmd:
        ena sec_reg;
        ax0 = dm(i3, m1);
        dm(tx_buf) = ax0;

        ax0 = i3;
        ay0 = init_cmds;
        ar = ax0 - ay0;
        if gt rti;

        ax0 = 0xaf00;
        dm(tx_buf) = ax0;

        ax0 = 0;
        dm(stat_flag) = ax0;
        rti;
