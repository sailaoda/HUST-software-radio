%% ************** Preparation part ********************
clear all; clc;
% system parameters
ml = 2;                      % Modulation level: 2--4QAM; 4--16QAM; 6--64QAM
NormFactor = sqrt(2/3*(ml.^2-1));
gi = 1/4;                   % Guard interval: in the Brazil_E model,the maxmum delay is 2e-6s, equals to 16 points. 
fftlen = 64;
gilen = gi*fftlen;           % Length of guard interval (points)
blocklen = fftlen + gilen;   % total length of the block with CP

% index define
DataSubcPatt = [1:5 7:19 21:26 27:32 34:46 48:52]';
DataSubcIdx = [7:11 13:25 27:32 34:39 41:53 55:59];
PilotSubcPatt = [6 20 33 47];
PilotSubcIdx = [12 26 40 54];
UsedSubcIdx = [7:32 34:59];
reorder = [33:64 1:32];

% packet information
NumBitsPerBlk = 48*ml;
NumBlksPerPkt = 50;
NumBitsPerPkt = NumBitsPerBlk*NumBlksPerPkt;

%% *********************** Transmitter ******************************
% Generate the information bits
inf_bits = randn(1,NumBitsPerPkt)>0;

%Modulate
paradata = reshape(inf_bits,length(inf_bits)/ml,ml);
ModedSeq = qammod(bi2de(paradata),2^ml)/NormFactor;

%Mapping
mod_ofdm_syms = zeros(52, NumBlksPerPkt);
mod_ofdm_syms(DataSubcPatt,:) = reshape(ModedSeq, 48, NumBlksPerPkt);
mod_ofdm_syms(PilotSubcPatt,:) = 1;
syms_into_ifft = zeros(64, NumBlksPerPkt);
syms_into_ifft(UsedSubcIdx,:) = mod_ofdm_syms;
syms_into_ifft(reorder,:) = syms_into_ifft;

% Convert to time domain
tx_blks = sqrt(64)*ifft(sqrt(64/52)*syms_into_ifft);

% Guard interval insertion
tx_frames = [tx_blks(fftlen-gilen+1:fftlen,:); tx_blks];
% P/S
tx_seq = reshape(tx_frames,NumBlksPerPkt*blocklen,1);


%% *********************** Receiver ******************************
rx_signal = tx_seq;

data_syms = reshape(rx_signal, 80, NumBlksPerPkt);
% remove guard intervals
data_syms(1:16,:) = [];

% perform fft
freq_data = fft(data_syms)/(64/sqrt(52));

% De-mapping
freq_data(reorder,:) = freq_data;
freq_data_syms = freq_data(DataSubcIdx,:);
freq_pilot_syms = freq_data(PilotSubcIdx,:);    

% P/S
Data_seq = reshape(freq_data_syms,48*NumBlksPerPkt,1);

% demodulate
DemodSeq = de2bi(qamdemod(Data_seq*NormFactor,2^ml));
SerialBits = reshape(DemodSeq,size(DemodSeq,1)*ml,1).';

num_err = sum(abs(SerialBits-inf_bits));
