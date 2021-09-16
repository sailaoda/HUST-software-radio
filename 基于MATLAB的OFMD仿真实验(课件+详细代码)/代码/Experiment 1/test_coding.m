clc; clear all;

trellis = poly2trellis(7,[133 171]); % 1/2
code_rate = 1/2;
tb = 7*5;
snr = 1;
% tb is a positive integer scalar that specifies the traceback depth.
% If the code rate is 1/2, a typical value for tblen is about five times 
% the constraint length of the code (here, K = 7). 

info_bits_len = 200;
inf_bits = randn(1,info_bits_len)>0;
coded_bits = convenc(inf_bits,trellis);
tx = 2*coded_bits-1;

noise_var = 1/(10^(snr/10))/2;
len = length(tx);
noise = sqrt(noise_var) * (randn(1,len) + j*randn(1,len));
% add noise
rx_signal = tx + noise;

hard_decision = rx_signal > 0;
raw_err_bits = sum(abs(hard_decision-coded_bits));
DecodedBits = vitdec(hard_decision,trellis,tb,'trunc','hard');
err = sum(abs(DecodedBits-inf_bits))