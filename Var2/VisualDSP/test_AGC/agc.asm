#include    "def2181.h"

#define M 4  
#define K 2

.SECTION/DM		data1;

.var/circ rx_buf[3];
.var/circ tx_buf[3];

.var/circ delay[M];
.var S;
.var ref;
.var mu;



/*** Interrupt Vector Table ***/
.SECTION/PM     interrupts;
			jump start;  rti; rti; rti;     /*00: reset */
        	jump agc;         rti; rti; rti;     /*04: IRQ2 - placa EZKIT*/
        	rti;         rti; rti; rti;     /*08: IRQL1 */
        	rti;         rti; rti; rti;     /*0c: IRQL0 */
       		rti;         rti; rti; rti;     /*10: SPORT0 tx */
      		rti; 	     rti; rti; rti;     /*14: SPORT1 rx */
        	rti;         rti; rti; rti;     /*18: IRQE */
        	rti;         rti; rti; rti;     /*1c: BDMA */
        	rti;         rti; rti; rti;     /*20: SPORT1 tx or IRQ1 */
        	rti;         rti; rti; rti;     /*24: SPORT1 rx or IRQ0 */
        	rti;         rti; rti; rti;     /*28: timer */
        	rti;         rti; rti; rti;     /*2c: power down */


.SECTION/PM		seg_code;
/*******************************************************************************
 *
 *  ADSP 2181 intialization
 *
 *******************************************************************************/
start:

si=0;
dm(S)=si;
ay1=0; // g(n-1) fractional part 
ax1=0; // g(n-1) integer part 
si=0.5r;
dm(ref)=si;
si=0.05r;
dm(mu)=si;

se=-K;

l3=M;
i3=delay;
m3=1;

imask=0x200;

stop: nop;
jump stop;

agc:
/*
y(n) = g(n-1)*x(n)
g(n)=g(n-1)+mu*(ref-S)
S = sum{|x(k)|}/M
*/

call read_input; 	// ar - input
mx0=ar; 			// save input

mr=0;
my0=-1.0r;

ar = ax1-1;
if lt jump g_fr;
mr=mr-mx0*my0 (ss);  // mr1 = x(n);
g_fr:
my1=ay1;	
mr=mr+mx0*my1 (rnd); // mr1= y(n) = interger_part_g(n-1)*x(n-1)+fractional_part_g(n-1)*x(n) <1

dm(tx_buf+2)=mr1;	// write output

//
ar = abs mr1;
sr=ashift ar (hi); // sr1 - scaled input 
dm(i3,m3)=sr1; 	   // update delay line

// compute average
cntr=M-1;
mr=0, mx0=dm(i3,m3);
do sum until ce;
sum: mr=mr-mx0*my0(ss), mx0=dm(i3,m3);
mr=mr-mx0*my0(rnd);
if mv sat mr;

dm(S)=mr1;

ax0=dm(ref);
ay0=dm(S);
ar=ax0-ay0; // ar=ref-S

// ay1= fractional part of g(n-1);
// ax1 = integer part of g(n-1)

my1=ar;
mx1=dm(mu);

mr=mx1*my1 (ss);	// mr1 = mu*(ref-S)
ar=mr1+ay1;			// ar = g(n-1)+ mu*(ref-S) = g(n)
af = pass ar;		// ar < 0 -> overflow g(n)>1, update integer and fractional parts
if ge jump cont;
// gain correction: ax1=1 -> ax1=1, ay1=0; ax1=1 -> ax1=0; ay1=0x7FFF
af = ax1-1;
if lt jump cor1;
// ax1=1 -> ay1=1.0, ax1=0;
ax1=0;
ay1=0x7fff;
rti;
// ax1=0 -> ay1=0.0, ax1=1
cor1:
ax1=1;
ay1=0;
rti;

cont:
ay1=ar;

rti;



////////////////////////////////////////////////
// Input, Output functions
////////////////////////////////////////////////

read_input:
	ar=dm(rx_buf+2);
	rts;
write_output:
	dm(tx_buf+2)=mr1;
	rts;

	
