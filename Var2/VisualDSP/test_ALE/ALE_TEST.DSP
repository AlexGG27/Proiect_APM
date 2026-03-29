
/****************************************************************
 *
 *  Acest program testeaza filtrul ALE :
 *
 *  - tabelul de intreruperi specific ADSP2181
 *  - rutinele de servire a intreruperilor
 *****************************************************************/




.extern fir;
.extern lms;
.extern llms;
.extern read_input;
.extern write_output;

#include "ale.h"		//definirea constantelor

.section/dm data1;

.var/circ	fir_d[n];	//linia de intirziere a FIR
.var/circ	input[n];	//linia de intirziere pentru intrare

.section/pm data2;

.var/circ	hh[n];		//coeficientii FIR

.section/dm data1;

.var/circ rx_buf[3];
.var/circ tx_buf[3];
.global rx_buf;
.global tx_buf;
.var save;

//Tabela vectorilor de intrerupere

.section/pm IVreset;

        jump start;  rti; rti; rti;     // 00: reset 
       	jump input_samples;         
		             rti; rti; rti;     // 04: IRQ2 
        rti;         rti; rti; rti;     // 08: IRQL1 
        rti;         rti; rti; rti;     // 0c: IRQL0 
        rti;		 rti;rti;rti;     // 10: SPORT) tx
        rti; 	     rti; rti; rti;     // 14: SPORT1 rx 
        rti;         rti; rti; rti;     // 18: IRQE 
        rti;         rti; rti; rti;     // 1c: BDMA 
        rti;         rti; rti; rti;     // 20: SPORT1 tx or IRQ1 
        rti;         rti; rti; rti;     // 24: SPORT1 rx or IRQ0 
        rti;         rti; rti; rti;     // 28: timer 
        rti;         rti; rti; rti;     // 2c: power down 

.section/pm program;
start: 
	//initializari registre
        
	m1=1;
	m5=1;
	si=0;
	i2=input;
	l2=n;
	i4=input+delay;
	l4=n;
	i3=fir_d;
	l3=n;
	i6=hh;
	l6=n;

	//initializare linii intirziere si coeficienti

	cntr=n;
	do init_buf until ce;
	dm(i2,m1)=si;
	dm(i3,m1)=si;
init_buf:
	pm(i6,m5)=si;

   imask =0x200;;
        

        //Asteptare intreruperi
                
wait:   jump wait;

//Rutina de servire a intreruperii de esantionare IRQ2}

input_samples:
    ena sec_reg;            // se utilizeaza setul secundar de registre 
	ena ar_sat;

	call read_input;	// in ar - esantionul de intrare
	dm(save)=ar;
	
	dm(i2,m1)=ar;		// actualizeaza linia de intirziere de intrare
	ar=dm(i4,m5);	
	dm(i3,m1)=ar;		// actualizeaza linia de intirziere a FIR
        
	//calculeaza iesirea FIR

	cntr=n-1;
	call fir;		// mr1 - iesirea filtrului

	//scrie iesirea - semnalul "curatat"

	call write_output;	//in mr1 - valoarea dorita pentru scriere

	//calcul eroare

	ar=dm(save);	// in ar - esantionul de intrare
	ay0=ar;
 	ar=ay0-mr1;		// in ar - eroarea
	mx0=ar;
	cntr=n;
	my1=mu;
	m4=-1;
	m6=2;
	m3=-1;
	//call lms;		// adapteaza coeficientii FIR
	m7=0;
	mx1=lambda;
	call llms;
        dis sec_reg;           // revine la setul primar de registre
        rti;





