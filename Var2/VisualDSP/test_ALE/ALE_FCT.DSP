/* Acest program implementeaza rutinele de filtrare FIR si de adaptare
a coeficientilor conform algoritmului LLMS (Leaky LMS).
*/ 
  

.section/pm program;

.global fir;
.global llms;


// ----------------FIR Subroutine--------------------------
/*
i3 = ^ filter input;
i6 = ^ filter coeficients
m1=1;m5=1;
mr1 = filter output
*/

fir:            mr=0, mx0=dm(i3,m1), my0=pm(i6,m5);
                do sop until ce;
sop:               mr=mr+mx0*my0(ss), mx0=dm(i3,m1), my0=pm(i6,m5);
                mr=mr+mx0*my0(rnd);
                if mv sat mr;
                rts; 

//----------------LLMS Modify Subroutine-----------------------

// h(k) = h(k)*(1-mu*lambda) + mu*x(n-k)*e(n)
/*

mx0 = error
my1 = mu
mx1 = lambda

m7=0;

i3 = ^ filter input;
i6 = ^ filter coeficients
m1=1;m5=1;m4=-1;m6=2;m3=-1;
mr1 = filter output
*/

llms:           mr=mx0*my1(rnd), mx0=dm(i3,m1);   // mr1 = error * mu , mx0= x(n-k)
				my0=mr1;						  // my0 = error*mu
                mr=mx0*my0(rnd), ay0=pm(i6,m5);	  // mr1 = x(n-k)*mu*error, ay0= h(k)
                
                do adaptive1 until ce;
                ar=mr1+ay0, mx0=dm(i3,m1), ay0=pm(i6,m4); //ar = h(k) +x(n-k)*mu*error
               
                mf=mx1*my1(rnd), sr1=pm(i6,m7);	  // mf= mu*lambda, sr1=h(k)
				mr=sr1*mf(rnd); 				  // mr1=h(k)*mu*lambda
				ay1 = mr1;		  				  // ay1=h(k)*mu*lambda
				
                ar=ar-ay1;						  //ar = h(k)-h(k)*mu*lambda+x(n-k)*mu*error
                

adaptive1:      pm(i6,m6)=ar, mr=mx0*my0(rnd);
               
				modify(i3,m3);
                modify(i6,m4);
                rts;


