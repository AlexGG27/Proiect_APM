
.section/pm program;

.global read_input;
.global write_output;

.extern rx_buf;
.extern tx_buf;


read_input:
	ar=dm(rx_buf+2);
	rts;
write_output:
	dm(tx_buf+2)=mr1;
	rts;

