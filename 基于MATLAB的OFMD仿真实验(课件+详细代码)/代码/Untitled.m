clear all;
clc;
close all;

ml = 2;
NormFactor = sqrt(2/3*(ml.^2-1));
fs = 20e6;
gi = 1/4;
fftlen = 64;
gilen = gi * fftlen;
blocklen = fftlen + gilen;

DataSubcPatt = [1:5,7:19,21:26,27:32,34:46,48:52];
DataSubcIdx = [7:11,13:25,27:32,34:39,41:53,55:59];
PilotSubcPatt = [6,20,33,47];
PilotSubcIdx = [12,26,40,54];
UsedSubcIdx = [7:32,34:59];
reorder = [33:64,1:32];

trellis = poly2trellis([7],[133,177]);
tb = 7*5;
ConvCodeRate = 1/2;
interleavebits = 1;

ShortTrain = sqrt(13/6) * [0,0,1+1j,0,0,0,-1-1j,0,0,0,1+1j,0,0,0,-1-1j,0,0,0,-1-1j,0,...
		0,0,1+1j,0,0,0,0,0,0,-1-1j,0,0,0,-1-1j,0,0,0,1+1j,0,0,0,1+1j,0,0,0,1+1j,0,0,0,1+1j,0,0]';
	NumShortTrainBlks = 10;
    NumShortComBlks = 16*NumShortTrainBlks/blocklen;
    LongTrain = ...
		[...
		1,1,-1,-1,1,1,-1,1,-1,1,1,1,1,...
		1,1,-1,-1,1,1,-1,1,-1,1,1,1,1,...
		1,-1,-1,1,1,-1,1,-1,1,-1,-1,-1,-1,...
		-1,1,1,-1,-1,1,-1,1,-1,1,1,1,1]';
	NumLongTrainBlks = 2; 
   %short_train = tx_freqd_to_timod(ShortTrain);
% tx_freqd_to_timod: transport part ==> frequency domain to time domain(moded)?
% input: ShortTrain: moded OFDM symbols -> column vector
% output: short_train: IFFTed symbols(in time domain) -> column vector
num_symbols = size(ShortTrain,2);
UsedSubcIdx = [7:32,34:59];
% user subcarrier index
resample_patt = [33:64,1:32];
% resample -- put the negative part forward
syms_into_ifft = zeros(64,num_symbols);
syms_into_ifft(UsedSubcIdx,:) = ShortTrain;
syms_into_ifft(resample_patt,:) = syms_into_ifft;
% this is a mapping
short_train = sqrt(64) * ifft(sqrt(64/52) * syms_into_ifft);
% normalized IFFT
short_train_blk = short_train(1:16);
short_train_blks = repmat(short_train_blk,NumShortTrainBlks,1);


% tx_freqd_to_timod: transport part ==> frequency domain to time domain(moded)?
% input: ShortTrain: moded OFDM symbols -> column vector
% output: short_train: IFFTed symbols(in time domain) -> column vector
num_symbols = size(LongTrain,2);
UsedSubcIdx = [7:32,34:59];
% user subcarrier index
resample_patt = [33:64,1:32];
% resample -- put the negative part forward
syms_into_ifft = zeros(64,num_symbols);
syms_into_ifft(UsedSubcIdx,:) = LongTrain;
syms_into_ifft(resample_patt,:) = syms_into_ifft;
% this is a mapping
long_train = sqrt(64) * ifft(sqrt(64/52) * syms_into_ifft);
% normalized IFFT
%long_train = tx_freqd_to_timod(LongTrain);
% generate the IFFT symbols of long train part
long_train_syms = [long_train(fftlen-2*gilen+1:fftlen,:);long_train;long_train];


preamble = [short_train_blks;long_train_syms];%10个重复短序列和2个重复长序列构成训练序列

NumBitsPerBlk = 48*ml*ConvCodeRate;
NumBlksPerPkt = 50;

NumPkts = 500;

NumBitsPerPkt = NumBitsPerBlk * NumBlksPerPkt;
  
CFO =0.1*fs/fftlen;
h = zeros(gilen,1);
h(1) = 1;
h(2) = 0.4;
h(3) = 0.3;
h(4) = 0.1;
h = h/norm(h);
channel =  fft(h,64);
channel([33:64,1:32]) =channel;
channel = channel([7:32,34:59]);


extranoise = 500;
snr = -5:5:10;
ber = zeros(1,length(snr));

per = zeros(1,length(snr));

for snr_index = 1:length(snr)                             %对不同信噪比循环
    numerr = 0;
    err = zeros(1,NumPkts);
    for pkt_index = 1:NumPkts
        [snr_index,pkt_index]
        
        inf_bits = randn(1,NumBitsPerPkt) > 0;
        codedseq = convenc(inf_bits,trellis);
        
           % rdy_to_mod_bits = tx_interleaver( codedseq,48,ml);
        paradata = reshape(rdy_to_mod_bits,length(rdy_to_mod_bits)/ml,ml]);
      ModedSeq = qammod(bi2de(paradata),2.^ml) / NormFactor;
      
      mod_ofdm_syms = zeros(52,NumBlksPerPkt);
	mod_ofdm_syms(DataSubcPatt,:) = reshape(ModedSeq,[48,NumBlksPerPkt*2]);
	mod_ofdm_syms(PilotSubcPatt,:) = 1;
		% put all of them into it
        
        
        
        
	%short_train = tx_freqd_to_timod(ShortTrain);
% tx_freqd_to_timod: transport part ==> frequency domain to time domain(moded)?
% input: ShortTrain: moded OFDM symbols -> column vector
% output: short_train: IFFTed symbols(in time domain) -> column vector
num_symbols = size(mod_ofdm_syms,2);
UsedSubcIdx = [7:32,34:59];
% user subcarrier index
resample_patt = [33:64,1:32];
% resample -- put the negative part forward
syms_into_ifft = zeros(64,num_symbols);
syms_into_ifft(UsedSubcIdx,:) = mod_ofdm_syms;
syms_into_ifft(resample_patt,:) = syms_into_ifft;
% this is a mapping
tx_blks = sqrt(64) * ifft(sqrt(64/52) * syms_into_ifft);
% normalized IFFT



tx_frames = [tx_blks(fftlen - gilen + 1:fftlen,:) ; tx_blks];
tx_seq = reshape(tx_frames,NumBitsPerPkt*blocklen,1);
tx = [preamble:tx_seq];


Fadedsignal = filter(h,1,tx);
len = length(Fadedsignal);
noise = sqrt(noise_var) * (randn(len,1)+j*randn(len,1));%模拟噪声

rx_signal = Fadedsignal + noise;   
extra_noise = sqrt(noise_var) * (randn(extranoise,1)+j*randn(extranoise,1));
end_noise = sqrt(noise_var)*(randn(170,1))+j*randn(170,1);
 rx =[extra_noise;rx_signal;end_noise];
 
 total_length = length(rx);
 t =[0:total_length]/fs;
 phase_shift = exp(j*2*pi*CFO*t).';
 rx =rx.* phase_shift;
 
 
 %packet  search
 rx_signal =rx_find_packet_edge(rx);
 
 %
 rx_signal=rx_frequency_sync(rx_signal,fs);
 fine_time_est = rx_fine_time_sync(rx_signal,long_train);
 
 
 sync_time_signal =rx_signal(fine_time_est:length(rx_signal));
 expect_length = 64*2+80*NumBlksPerPkt;
 [freq_tr_syms,freq_data_syms,freq_pilot_syms]=rx_timed_to_freq(sync_time_signal(1:expected_length));
 
 %
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 rx_timed_to_freq
 freq_long_tr=fft(long_tr_syms)/(64/sqrt(52));
 reorder=[33:64 1:32];
 freq_long_tr(reorderr,:)=freq_long_tr;
 
 %
 
 freq_tr_syms=freq_long_tr(UsedSubcIdx,:);
 
 %
 
 data_syms=time_signal(129:length(time_signal));
 
 data_sig_len=length(data_syms);
 n_data_syms=floor(data_sig_len/80);
 
 %
 
 data_syms=data_syms(1:n_data_syms*80);
 data_syms=reshape(data_syms,80,n_data_syms);
 
 %
 
 data_syms(1:16,:)=[];
 
 %
 
 freq_data=fft(data_syms)/(64/sqrt(52));
 
 %
 
 dreq_data(reorder,:)=freq_data;
 
 %
 
 freq_data_syms=freq_data(DataSubcIdx,:);
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
channel_est=mean(freq_tr_syms,2).*conj(LongTrain);

%
chan_corr_mat=repmat(channel_est(DataSubcPatt),1,size(freq_data_syms));
freq_data_syms=freq_data_syms.*conj(chan_corr_mat);
chan_corr_mat=repat(channel_est(PilotSubcPatt),1,size(freq_pilot_syms));
freq_pilot_syms=freq_pilot_syms.*conj(chan_corr_mat);

%
chan_sq_amplitude=sum(abs(channel_est(DataSubcPatt,:)).^2,2);
chan_sq_amplitude_mtx=repmat(chan_sq_amplitude,1,size(freq_data_syms));
pilot_syms_out=freq_pilot_syms./chan_sq_amplitude_mtx;

phase_est=angle(sum(pilot_syms_out));
phase_comp=exp(-j*phase_est);
data_syms_out=data_syms_out.*remat(phase_comp,48,1);

Data_seq=reshape(data_syms_out,48*NumBlksPerPkt,1);

%
DemodSeq = de2bi(qamdemod(Data_seq * NormFactor,2^ml));
deint_bits=DemodSeq;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 DecodedBits=vitdec(deint_bits(1:length(CodedSeq)),trellis,tb,'tr)
 %
 
 
 
 
 
