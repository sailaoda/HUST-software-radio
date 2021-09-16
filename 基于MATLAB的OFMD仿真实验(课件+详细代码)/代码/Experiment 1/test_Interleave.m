fftlen = 48;
ml = 2;
sym_num = 10;
bits_len = fftlen*ml*sym_num;
inf_bits = randn(1,bits_len)>0;
inf_bits = [1:bits_len];

interleaved_bits = tx_interleaver(inf_bits,fftlen, ml);

deint_bits = rx_deinterleave(interleaved_bits, fftlen, ml);

sum(abs(inf_bits-inf_bits))