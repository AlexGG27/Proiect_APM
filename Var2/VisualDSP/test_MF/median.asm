#include    "def2181.h"

#define W 3  
#define K 1


.SECTION/DM		data1;

.var/circ rx_buf[3];
.var/circ tx_buf[3];

.var/circ delay[W];
.var delay_sorted[W];


/*** Interrupt Vector Table ***/
.SECTION/PM     interrupts;
			jump start;  rti; rti; rti;     /*00: reset */
        	jump median_f;         rti; rti; rti;     /*04: IRQ2 - placa EZKIT*/
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

l3=W;
i3=delay;
m3=1;
l0=0;

imask=0x200;

stop: nop;
jump stop;

median_f:

call read_input; // ar - input
dm(i3,m3)=ar; 	 // update delay line

// copy delay to delay sorted
i0=delay_sorted;
cntr=W;
do copy until ce;
si=dm(i3,m3);
copy:
dm(i0,m3)=si;

i2=delay_sorted;
call sort_sel;
// median value
i0=delay_sorted;
m0=K;
modify(i0,m0);
ar=dm(i0,m3);
dm(tx_buf+2)=ar;


rti;


/////////////////////////////////////////////////////////////////////
// sortare prin selectie
sort_sel:
/*
	for (i=0; i<W; i++)
		{
			min=i; 
			for (j=i+1; j<W; j++)
				{
				if A[j]<A[min] min=j;
				}
			tmp=A[i];
			A[i]=A[min];
			A[min]=tmp;
		}
*/


// sorting


// m0 - min
// m1 - (i)
// m2 - (i+1)

// i2 pointer to A

m3=1;

l0=0;
l1=0;

cntr=W;
// 	for (i=0; i<W-1; i++)
do loop_i until ce;
ax0=W;
ay0=cntr;
ar=ax0-ay0; //i
m0=ar; 		// m0 = min
m1=ar;		// m1 = i

ar=ar+1;
m2=ar;		// m2 = i+1
ay0=m1;
ar=ax0-ay0; 
ar=ar-1;	// # of iteration in loop_j


if eq jump loop_i;

cntr=ar;



i0=i2;
modify(i0,m2);	// i0=A[i+1]

// for (j=i+1; j<W; j++)
	do loop_j until ce;
	//if A[j]<A[min] min=j;
	ax0=dm(i0,m3); // ax0= A[j]
	i1=i2;
	modify(i1,m0);
	ay0=dm(i1,m3); // ay0=A[min]
	ar=ax0-ay0;
	if gt jump loop_j;
	ax0=W;
	ay0=cntr;
	ar=ax0-ay0; //j
	m0=ar; 		// min = j
	loop_j: nop;
/*
tmp=A[i];
A[i]=A[min];
A[min]=tmp;
*/
i1=i2;
modify(i1,m1);
ax1=dm(i1,m3);	// ax1 = tmp = A[i];
i1=i2;
modify(i1,m0);	
ay1=dm(i1,m3);	// ay1=A[min]
i1=i2;
modify(i1,m1);
dm(i1,m3)=ay1;	// A[i]=A[min]
i1=i2;
modify(i1,m0);	
dm(i1,m3)=ax1;	// A[min]=tmp


loop_i: nop;



rts;

////////////////////////////////////////////////
// Input, Output functions
////////////////////////////////////////////////

read_input:
	ar=dm(rx_buf+2);
	rts;
write_output:
	dm(tx_buf+2)=mr1;
	rts;

	
