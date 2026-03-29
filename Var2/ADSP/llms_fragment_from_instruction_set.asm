; Exact reference fragment transcribed from adsp21xx._instruction_set.pdf

MF=MX0*MY1(RND), MX0=DM(I2,M1); {MF=error *beta}
MR=MX0*MF(RND), AY0=PM(I6,M5);
DO adapt UNTIL CE;
AR=MR1+AY0, MX0=DM(I2,M1), AY0=PM(I6,M7);
adapt: PM(I6,M6)=AR, MR=MX0 *MF(RND);
MODIFY(I2,M3); {Point to oldest data}
MODIFY(I6,M7); {Point to start of data}
