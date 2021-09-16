%% ************** Preparation part ********************
clear all; clc;
% system parameters
ml = 4;                      % Modulation level: 2--4QAM; 4--16QAM; 6--64QAM
NormFactor = sqrt(2/3*(ml.^2-1));
gi = 1/4;                   % Guard interval: in the Brazil_E model,the maxmum delay is 2e-6s, equals to 16 points. 
fftlen = 64;
gilen = gi*fftlen;           % Length of guard interval (points)
blocklen = fftlen + gilen;   % total length of the block with CP
bits_per_sym = fftlen*ml;

trellis = poly2trellis(7,[133 171]); % 1/2
code_rate = 1/2;
tb = 7*5;
% tb is a positive integer scalar that specifies the traceback depth.
% If the code rate is 1/2, a typical value for tblen is about five times 
% the constraint length of the code (here, K = 7). 

info_bits_per_sym = bits_per_sym*code_rate;
NumSyms = 4000;
TotalInfoBits = info_bits_per_sym*NumSyms;

%% ************** channel ***************************
h = zeros(gilen,1);
h(1) = 1;
h(5) = 0.5;
h(10) = 0.3;
H = fft(h,fftlen);
%plot(abs(H));

snr = [8:2:16];
ber = zeros(1,length(snr));

for snr_idx = 1:length(snr)
    snr(snr_idx)
    %% *********************** Transmitter ******************************
    % Generate the information bits
    inf_bits = randn(1,TotalInfoBits)>0;
    coded_bits = convenc(inf_bits,trellis);

    interleaved_bits = tx_interleaver(coded_bits,fftlen, ml);

    %Modulate
    paradata = reshape(interleaved_bits,length(interleaved_bits)/ml,ml);
    mod_ofdm_syms = qammod(bi2de(paradata),2^ml)/NormFactor;
    mod_ofdm_syms = reshape(mod_ofdm_syms,fftlen,NumSyms);

    tx_blks = sqrt(fftlen)*ifft(mod_ofdm_syms);

    % Guard interval insertion
    tx_frames = [tx_blks(fftlen-gilen+1:fftlen,:); tx_blks];
    % P/S
    tx = reshape(tx_frames,NumSyms*blocklen,1);

    %% *********************** Channel ******************************
    rx_signal = filter(h,1,tx);
    noise_var = 1/(10^(snr(snr_idx)/10))/2;
    len = length(rx_signal);
    noise = sqrt(noise_var) * (randn(len,1) + j*randn(len,1));
    % add noise
    rx_signal = rx_signal + noise;

    %% *********************** Receiver ******************************
    rx_signal = reshape(rx_signal, blocklen, NumSyms);
    rx_signal([1:16],:) = [];
    freq_data = fft(rx_signal)/sqrt(fftlen);     
    cha_mtx = repmat(H,1,NumSyms);
    cha_amp_mtx = repmat(abs(H).^2,1,NumSyms);
    freq_data_cha_equ = freq_data.*conj(cha_mtx)./cha_amp_mtx;

    Data_seq = reshape(freq_data_cha_equ,fftlen*NumSyms,1)*NormFactor;

    % demodulate
    DemodSeq = de2bi(qamdemod(Data_seq,2^ml),ml);
    SerialBits = reshape(DemodSeq,size(DemodSeq,1)*ml,1).';

    deint_bits = rx_deinterleave(SerialBits, fftlen, ml);

    DecodedBits = vitdec(deint_bits,trellis,tb,'trunc','hard');
    err = sum(abs(DecodedBits-inf_bits));
    ber(snr_idx) = err/TotalInfoBits;
end
semilogy(snr,ber,'-b.');
