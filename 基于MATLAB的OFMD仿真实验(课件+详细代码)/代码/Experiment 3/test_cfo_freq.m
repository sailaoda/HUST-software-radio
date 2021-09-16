clear all; clc;

%% ************** System parameters ********************
M = 4;                      % Modulation level: 4--4QAM; 16--16QAM;
fftlen = 64;
NumSyms = 50;
TotalNumSyms = fftlen*NumSyms;
    
%% *********************** Transmitter ******************************
x = randi([0 M-1],TotalNumSyms,1);
mod_ofdm_syms = qammod(x,M);

mod_ofdm_syms = reshape(mod_ofdm_syms,fftlen,NumSyms);
tx_blks = sqrt(fftlen)*ifft(mod_ofdm_syms);

% P/S
tx = reshape(tx_blks,NumSyms*fftlen,1);

%% *********************** Channel ******************************
cfo = 0.1/fftlen;
time = [0:length(tx)-1]';
rx_signal = tx.*exp(j*2*pi*cfo*time);

%% *********************** Receiver ******************************
rx_signal = reshape(rx_signal, fftlen, NumSyms);
freq_data = fft(rx_signal)/sqrt(fftlen);  
for frame_idx = 1:NumSyms
    scatterplot(freq_data(:,frame_idx));
end

