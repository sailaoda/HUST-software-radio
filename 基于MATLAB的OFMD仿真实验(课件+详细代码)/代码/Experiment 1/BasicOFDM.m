clear all; clc;

%% ************** System parameters ********************
ml = 4;                      % Modulation level: 2--4QAM; 4--16QAM; 6--64QAM   (调制阶数/星座大小)
NormFactor = sqrt(2/3*(ml.^2-1));
%NormFactor = 1;
gi = 1/4;                   % Guard interval: in the Brazil_E model,the maxmum delay is 2e-6s, equals to 16 points. 
fftlen = 64;                % FFT大小/长度
gilen = gi*fftlen;           % Length of guard interval (points)    (GI的长度，没保护间隔时，gilen = 0)
blocklen = fftlen + gilen;   % total length of the block with CP    (符号周期)
bits_per_sym = fftlen*ml;
NumSyms = 50;
TotalNumBits = bits_per_sym*NumSyms;

%% ************** channel ***************************
h = zeros(gilen,1);     
h(1) = 1;
h(3) = 0.4;
h(6) = 0.2;
H = fft(h,fftlen);
%plot(abs(H));

snr = 30;
    
%% *********************** Transmitter ******************************
% Generate the information bits
inf_bits = randn(1,TotalNumBits)>0;

%Modulate
paradata = reshape(inf_bits,length(inf_bits)/ml,ml);
mod_ofdm_syms = qammod(bi2de(paradata),2^ml)./NormFactor;

mod_ofdm_syms = reshape(mod_ofdm_syms,fftlen,NumSyms);
tx_blks = sqrt(fftlen)*ifft(mod_ofdm_syms);

% Guard interval insertion
tx_frames = [tx_blks(fftlen-gilen+1:fftlen,:); tx_blks];
% P/S
tx = reshape(tx_frames,NumSyms*blocklen,1);

%% *********************** Channel ******************************
rx_signal = filter(h,1,tx);
noise_var = 1/(10^(snr/10))/2;
len = length(rx_signal);
noise = sqrt(noise_var) * (randn(len,1) + j*randn(len,1));
% add noise
rx_signal = rx_signal + noise;

%% *********************** Receiver ******************************
rx_signal = reshape(rx_signal, blocklen, NumSyms);
rx_signal([1:16],:) = [];
freq_data = fft(rx_signal)/sqrt(fftlen);  

%% check consistency
cha_mtx = repmat(H,1,NumSyms);
freq_data_check = mod_ofdm_syms.*cha_mtx;   %不同
plot(abs(freq_data(:,1)),'-b.'); 
hold on; 
plot(abs(freq_data_check(:,1)),'-ro');
