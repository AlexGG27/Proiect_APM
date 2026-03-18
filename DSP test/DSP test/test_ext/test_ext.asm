#include    "def2181.h"

#define PORT_OUT        0x00FF
#define PORT_IN         0x01FF

#define MODE_AGC        0
#define MODE_ALE        1
#define MODE_MF         2
#define MODE_BYPASS     3

#define CMD_VALID_MASK  0x00C0
#define CMD_VALID_BITS  0x00C0
#define CMD_ID_MASK     0x0007
#define CMD_CHANNEL_MASK 0x0008

#define AGC_BUF_LEN     32
#define MF_BUF_LEN      9
#define ALE_TAPS        32
#define ALE_BUF_LEN     256


.SECTION/DM     buf_var1;
.var    rx_buf[3];

.SECTION/DM     buf_var2;
.var    tx_buf[3] = 0xc000, 0x0000, 0x0000;

.SECTION/DM     buf_var3;
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

.SECTION/DM     data1;

.var    stat_flag;
.var    flag_cda = 0;

.var    current_command = 0x0000;
.var    current_switches = 0x0000;
.var    current_mode = MODE_BYPASS;
.var    current_channel = 0x0000;

.var    sample_left = 0x0000;
.var    sample_right = 0x0000;
.var    selected_input = 0x0000;
.var    selected_output = 0x0000;
.var    ale_noisy_input = 0x0000;

.var    debug_override_enable = 0x0000;
.var    debug_command = 0x00C0;
.var    debug_switches = 0x0000;

.var    agc_ref = 0x4000;
.var    agc_mu = 0x028f;
.var    agc_count = 0x0004;
.var    agc_shift = 0x0002;
.var    agc_gain_int = 0x0000;
.var    agc_gain_frac = 0x7fff;
.var    agc_abs_buffer[AGC_BUF_LEN];

.var    mf_window = 0x0003;
.var    mf_k_index = 0x0001;
.var    mf_delay[MF_BUF_LEN];
.var    mf_sorted[MF_BUF_LEN];

.var    ale_delay = 0x0020;
.var    ale_a = 0x1000;
.var    ale_mu = 0x0148;
.var    ale_lambda = 0x0042;
.var    ale_input[ALE_BUF_LEN];
.var    ale_fir[ALE_TAPS];
.var    noise_seed = 0xACE1;

.var    agc_ref_table[4] = 0x2000, 0x3000, 0x4000, 0x5000;
.var    agc_mu_table[4] = 0x0148, 0x028f, 0x0666, 0x0ccd;
.var    agc_count_table[4] = 0x0004, 0x0008, 0x0010, 0x0020;
.var    agc_shift_table[4] = 0x0002, 0x0003, 0x0004, 0x0005;

.var    mf_window_table[4] = 0x0003, 0x0005, 0x0007, 0x0009;
.var    mf_k_table[4] = 0x0001, 0x0002, 0x0003, 0x0004;

.var    ale_delay_table[4] = 0x0010, 0x0020, 0x0040, 0x0080;
.var    ale_a_table[4] = 0x0000, 0x1000, 0x2000, 0x4000;
.var    ale_mu_table[4] = 0x00a4, 0x0148, 0x028f, 0x051f;
.var    ale_lambda_table[4] = 0x0000, 0x0042, 0x00a4, 0x0148;

.var    display_table[4] = 0x003f, 0x0006, 0x005b, 0x0079;


.SECTION/PM     pm_da;
.var/circ ale_coeff[ALE_TAPS];


.SECTION/PM     interrupts;
        jump start;              rti; rti; rti;
        jump cmd_interrupt;      rti; rti; rti;
        rti;                     rti; rti; rti;
        rti;                     rti; rti; rti;
        ar = dm(stat_flag);
        ar = pass ar;
        if eq rti;
        jump next_cmd;
        jump input_samples;      rti; rti; rti;
        rti;                     rti; rti; rti;
        rti;                     rti; rti; rti;
        rti;                     rti; rti; rti;
        rti;                     rti; rti; rti;
        rti;                     rti; rti; rti;
        rti;                     rti; rti; rti;


.SECTION/PM     seg_code;

start:
        ax0 = b#0000100000000000;
        dm(Sys_Ctrl_Reg) = ax0;

        i5 = rx_buf;
        l5 = LENGTH(rx_buf);
        i6 = tx_buf;
        l6 = LENGTH(tx_buf);
        i3 = init_cmds;
        l3 = LENGTH(init_cmds);

        m1 = 1;
        m5 = 1;

        ax0 = b#0000110011010111;
        dm(Sport0_Autobuf_Ctrl) = ax0;

        ax0 = 0;
        dm(Sport0_Rfsdiv) = ax0;
        dm(Sport0_Sclkdiv) = ax0;

        ax0 = b#1000011000001111;
        dm(Sport0_Ctrl_Reg) = ax0;

        ax0 = b#0000000000000111;
        dm(Sport0_Tx_Words0) = ax0;
        dm(Sport0_Tx_Words1) = ax0;
        dm(Sport0_Rx_Words0) = ax0;
        dm(Sport0_Rx_Words1) = ax0;

        ax0 = b#0001100000000000;
        dm(Sys_Ctrl_Reg) = ax0;

        ifc = b#00000011111110;
        nop;

        icntl = b#00010;
        mstat = b#1100000;

        ax0 = 1;
        dm(stat_flag) = ax0;

        ena ints;
        imask = 0x0040;

        ax0 = dm(i6, m5);
        tx0 = ax0;

wait_codec_init:
        ax0 = dm(stat_flag);
        af = pass ax0;
        if ne jump wait_codec_init;

        ay0 = 2;
wait_aci_set:
        ax0 = dm(rx_buf);
        ar = ax0 and ay0;
        if eq jump wait_aci_set;

wait_aci_clear:
        ax0 = dm(rx_buf);
        ar = ax0 and ay0;
        if ne jump wait_aci_clear;

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

        si = 0xFFFF;
        dm(Dm_Wait_Reg) = si;

        si = 0x0000;
        dm(Prog_Flag_Comp_Sel_Ctrl) = si;

        si = 0x0000;
        dm(flag_cda) = si;
        dm(current_mode) = si;
        dm(current_channel) = si;
        dm(current_command) = si;
        dm(current_switches) = si;

        call reset_agc_state;
        call reset_mf_state;
        call reset_ale_state;

        ax0 = MODE_BYPASS;
        dm(current_mode) = ax0;
        si = 0x0079;
        IO(PORT_OUT) = si;

        imask = 0x0220;

main_wait:
        idle;
        jump main_wait;


cmd_interrupt:
        ax0 = 1;
        dm(flag_cda) = ax0;
        rti;


input_samples:
        ena sec_reg;

        ax0 = dm(rx_buf + 1);
        dm(sample_left) = ax0;
        ax0 = dm(rx_buf + 2);
        dm(sample_right) = ax0;

        ax0 = dm(flag_cda);
        ar = pass ax0;
        if eq jump process_sample;

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


latch_command:
        ax0 = dm(debug_override_enable);
        ar = pass ax0;
        if eq jump read_hw_command;
        ax0 = dm(debug_command);
        jump store_command_value;

read_hw_command:
        ax0 = dm(Prog_Flag_Data);
        ay0 = 0x00FF;
        ar = ax0 and ay0;
        ax0 = ar;

store_command_value:
        dm(current_command) = ax0;

        ax1 = dm(debug_override_enable);
        ar = pass ax1;
        if eq jump read_hw_switches;
        ax0 = dm(debug_switches);
        jump store_switch_value;

read_hw_switches:
        si = IO(PORT_IN);
        ax0 = si;
        ay0 = 0x00FF;
        ar = ax0 and ay0;
        ax0 = ar;

store_switch_value:
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


configure_agc:
        ax0 = dm(current_switches);
        ay0 = 0x00C0;
        ar = ax0 and ay0;
        sr = lshift ar by -6 (hi);
        m0 = sr1;
        i0 = agc_ref_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        dm(agc_ref) = ax0;

        ax0 = dm(current_switches);
        ay0 = 0x0030;
        ar = ax0 and ay0;
        sr = lshift ar by -4 (hi);
        m0 = sr1;
        i0 = agc_count_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        dm(agc_count) = ax0;
        i0 = agc_shift_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        dm(agc_shift) = ax0;

        ax0 = dm(current_switches);
        ay0 = 0x000C;
        ar = ax0 and ay0;
        sr = lshift ar by -2 (hi);
        m0 = sr1;
        i0 = agc_mu_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        dm(agc_mu) = ax0;

        call reset_agc_state;
        rts;


configure_mf:
        ax0 = dm(current_switches);
        ay0 = 0x0003;
        ar = ax0 and ay0;
        m0 = ar;

        i0 = mf_window_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        dm(mf_window) = ax0;

        i0 = mf_k_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        dm(mf_k_index) = ax0;

        call reset_mf_state;
        rts;


configure_ale:
        ax0 = dm(current_switches);
        ay0 = 0x00C0;
        ar = ax0 and ay0;
        sr = lshift ar by -6 (hi);
        m0 = sr1;
        i0 = ale_delay_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        dm(ale_delay) = ax0;

        ax0 = dm(current_switches);
        ay0 = 0x0030;
        ar = ax0 and ay0;
        sr = lshift ar by -4 (hi);
        m0 = sr1;
        i0 = ale_a_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        dm(ale_a) = ax0;

        ax0 = dm(current_switches);
        ay0 = 0x000C;
        ar = ax0 and ay0;
        sr = lshift ar by -2 (hi);
        m0 = sr1;
        i0 = ale_mu_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        dm(ale_mu) = ax0;

        ax0 = dm(current_switches);
        ay0 = 0x0003;
        ar = ax0 and ay0;
        m0 = ar;
        i0 = ale_lambda_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        dm(ale_lambda) = ax0;

        call reset_ale_state;
        rts;


update_display:
        ax0 = dm(current_mode);
        m0 = ax0;
        i0 = display_table;
        modify(i0, m0);
        ax0 = dm(i0, m1);
        ay0 = dm(current_channel);
        ar = pass ay0;
        if eq jump write_display_value;
        ay0 = 0x0080;
        ar = ax0 or ay0;
        ax0 = ar;

write_display_value:
        si = ax0;
        IO(PORT_OUT) = si;
        rts;


process_agc:
        ar = dm(selected_input);
        mx0 = ar;
        mr = 0;
        my0 = -1.0r;

        ax1 = dm(agc_gain_int);
        ay1 = dm(agc_gain_frac);
        ar = ax1 - 1;
        if lt jump agc_frac_only;
        mr = mr - mx0 * my0 (ss);

agc_frac_only:
        my1 = ay1;
        mr = mr + mx0 * my1 (rnd);
        dm(selected_output) = mr1;

        ar = abs mr1;
        i0 = agc_abs_buffer + AGC_BUF_LEN - 1;
        i1 = agc_abs_buffer + AGC_BUF_LEN - 2;
        m0 = -1;
        cntr = AGC_BUF_LEN - 1;
        do agc_shift_hist until ce;
        ax0 = dm(i1, m0);
agc_shift_hist:
        dm(i0, m0) = ax0;
        dm(agc_abs_buffer) = ar;

        i0 = agc_abs_buffer;
        ax0 = dm(agc_count);
        ar = ax0 - 1;
        cntr = ar;
        mr = 0, mx0 = dm(i0, m1);
        do agc_sum_loop until ce;
agc_sum_loop:
        mr = mr - mx0 * my0 (ss), mx0 = dm(i0, m1);
        mr = mr - mx0 * my0 (rnd);
        if mv sat mr;

        ar = mr1;
        ax0 = dm(agc_shift);
        cntr = ax0;
        do agc_scale_loop until ce;
        sr = ashift ar by -1 (hi);
agc_scale_loop:
        ar = sr1;

        ax0 = dm(agc_ref);
        ay0 = ar;
        ar = ax0 - ay0;
        my1 = ar;
        mx1 = dm(agc_mu);
        mr = mx1 * my1 (ss);
        ar = mr1 + ay1;
        af = pass ar;
        if ge jump agc_store_fraction;
        af = ax1 - 1;
        if lt jump agc_set_gain_max;
        ax1 = 0;
        ay1 = 0x7fff;
        jump agc_gain_done;

agc_set_gain_max:
        ax1 = 1;
        ay1 = 0;
        jump agc_gain_done;

agc_store_fraction:
        ay1 = ar;

agc_gain_done:
        dm(agc_gain_int) = ax1;
        dm(agc_gain_frac) = ay1;
        rts;


process_mf:
        ax0 = dm(selected_input);
        i0 = mf_delay + MF_BUF_LEN - 1;
        i1 = mf_delay + MF_BUF_LEN - 2;
        m0 = -1;
        cntr = MF_BUF_LEN - 1;
        do mf_shift_hist until ce;
        ax1 = dm(i1, m0);
mf_shift_hist:
        dm(i0, m0) = ax1;
        dm(mf_delay) = ax0;

        i0 = mf_sorted;
        i1 = mf_delay;
        ax0 = dm(mf_window);
        cntr = ax0;
        do mf_copy_window until ce;
        ax1 = dm(i1, m1);
mf_copy_window:
        dm(i0, m1) = ax1;

        i2 = mf_sorted;
        call sort_sel_window;

        i0 = mf_sorted;
        ax0 = dm(mf_k_index);
        m0 = ax0;
        modify(i0, m0);
        ax0 = dm(i0, m3);
        dm(selected_output) = ax0;
        rts;


sort_sel_window:
        m3 = 1;
        l0 = 0;
        l1 = 0;

        ax0 = dm(mf_window);
        cntr = ax0;
        do mf_loop_i until ce;
        ax0 = dm(mf_window);
        ay0 = cntr;
        ar = ax0 - ay0;
        m0 = ar;
        m1 = ar;

        ar = ar + 1;
        m2 = ar;
        ay0 = m1;
        ar = ax0 - ay0;
        ar = ar - 1;
        if eq jump mf_loop_i;

        cntr = ar;
        i0 = i2;
        modify(i0, m2);

        do mf_loop_j until ce;
        ax0 = dm(i0, m3);
        i1 = i2;
        modify(i1, m0);
        ay0 = dm(i1, m3);
        ar = ax0 - ay0;
        if gt jump mf_loop_j;
        ax0 = dm(mf_window);
        ay0 = cntr;
        ar = ax0 - ay0;
        m0 = ar;
mf_loop_j:
        nop;

        i1 = i2;
        modify(i1, m1);
        ax1 = dm(i1, m3);
        i1 = i2;
        modify(i1, m0);
        ay1 = dm(i1, m3);
        i1 = i2;
        modify(i1, m1);
        dm(i1, m3) = ay1;
        i1 = i2;
        modify(i1, m0);
        dm(i1, m3) = ax1;
mf_loop_i:
        nop;
        m1 = 1;
        rts;


process_ale:
        call generate_noise;
        mx0 = ar;
        my0 = dm(ale_a);
        mr = mx0 * my0 (rnd);
        ax0 = dm(selected_input);
        ay0 = mr1;
        ar = ax0 + ay0;
        dm(ale_noisy_input) = ar;

        dm(i2, m1) = ar;
        ar = dm(i4, m5);
        dm(i3, m1) = ar;

        cntr = ALE_TAPS - 1;
        call fir_ale;
        dm(selected_output) = mr1;

        ax0 = dm(ale_noisy_input);
        ay0 = mr1;
        ar = ax0 - ay0;
        mx0 = ar;
        cntr = ALE_TAPS;
        my1 = dm(ale_mu);
        m4 = -1;
        m6 = 2;
        m3 = -1;
        m7 = 0;
        mx1 = dm(ale_lambda);
        call llms_ale;
        rts;


generate_noise:
        ax0 = dm(noise_seed);
        ay0 = 0x0001;
        ar = ax0 and ay0;
        ar = ax0;
        sr = lshift ar by -1 (hi);
        ax0 = sr1;
        if eq jump noise_store;
        ay0 = 0xB400;
        ar = ax0 xor ay0;
        ax0 = ar;

noise_store:
        dm(noise_seed) = ax0;
        ar = ax0;
        rts;


fir_ale:
        mr = 0, mx0 = dm(i3, m1), my0 = pm(i6, m5);
        do fir_acc until ce;
fir_acc:
        mr = mr + mx0 * my0 (ss), mx0 = dm(i3, m1), my0 = pm(i6, m5);
        mr = mr + mx0 * my0 (rnd);
        if mv sat mr;
        rts;


llms_ale:
        mr = mx0 * my1 (rnd), mx0 = dm(i3, m1);
        my0 = mr1;
        mr = mx0 * my0 (rnd), ay0 = pm(i6, m5);

        do llms_loop until ce;
        ar = mr1 + ay0, mx0 = dm(i3, m1), ay0 = pm(i6, m4);
        mf = mx1 * my1 (rnd), sr1 = pm(i6, m7);
        mr = sr1 * mf (rnd);
        ay1 = mr1;
        ar = ar - ay1;
llms_loop:
        pm(i6, m6) = ar, mr = mx0 * my0 (rnd);

        modify(i3, m3);
        modify(i6, m4);
        rts;


reset_agc_state:
        ax0 = 0;
        dm(agc_gain_int) = ax0;
        ax0 = 0x7fff;
        dm(agc_gain_frac) = ax0;
        ax0 = 0;
        i0 = agc_abs_buffer;
        cntr = AGC_BUF_LEN;
        do reset_agc_loop until ce;
reset_agc_loop:
        dm(i0, m1) = ax0;
        rts;


reset_mf_state:
        ax0 = 0;
        i0 = mf_delay;
        cntr = MF_BUF_LEN;
        do reset_mf_delay until ce;
reset_mf_delay:
        dm(i0, m1) = ax0;

        i0 = mf_sorted;
        cntr = MF_BUF_LEN;
        do reset_mf_sorted until ce;
reset_mf_sorted:
        dm(i0, m1) = ax0;
        rts;


reset_ale_state:
        ax0 = 0xACE1;
        dm(noise_seed) = ax0;

        ax0 = 0;
        i0 = ale_input;
        cntr = ALE_BUF_LEN;
        do reset_ale_input until ce;
reset_ale_input:
        dm(i0, m1) = ax0;

        i0 = ale_fir;
        cntr = ALE_TAPS;
        do reset_ale_fir until ce;
reset_ale_fir:
        dm(i0, m1) = ax0;

        i6 = ale_coeff;
        l6 = ALE_TAPS;
        cntr = ALE_TAPS;
        do reset_ale_coeff until ce;
reset_ale_coeff:
        pm(i6, m5) = ax0;

        i2 = ale_input;
        l2 = ALE_BUF_LEN;
        i4 = ale_input;
        ax0 = dm(ale_delay);
        m4 = ax0;
        modify(i4, m4);
        l4 = ALE_BUF_LEN;
        i3 = ale_fir;
        l3 = ALE_TAPS;
        i6 = ale_coeff;
        l6 = ALE_TAPS;
        rts;


next_cmd:
        ena sec_reg;
        ax0 = dm(i3, m1);
        dm(tx_buf) = ax0;
        ax0 = i3;
        ay0 = init_cmds;
        ar = ax0 - ay0;
        if gt jump next_cmd_done;
        ax0 = 0xaf00;
        dm(tx_buf) = ax0;
        ax0 = 0;
        dm(stat_flag) = ax0;
next_cmd_done:
        rti;
