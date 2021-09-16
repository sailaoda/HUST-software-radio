%% ************** Preparation part ********************
clear all; clc;
% system parameters
fs = 20e6;
ml = 2;                      % Modulation level: 2--4QAM; 4--16QAM; 6--64QAM
NormFactor = sqrt(2/3*(ml.^2-1));
gi = 1/4;                   % Guard interval: in the Brazil_E model,the maxmum delay is 2e-6s, equals to 16 points. 
fftlen = 64;
gilen = gi*fftlen;           % Length of guard interval (points)
blocklen = fftlen + gilen;   % total length of the block with CP

% index define

DataSubcPatt = [1:5 7:19 21:26 27:32 34:46 48:52]';
PilotSubcPatt = [6 20 33 47];
UsedSubcIdx = [7:32 34:59];

% channel coding parameters
%trellis = poly2trellis([4 3],[4 5 17;7 4 2]); % 2/3
trellis = poly2trellis(7,[133 171]); % 1/2
% tb is a positive integer scalar that specifies the traceback depth.
% If the code rate is 1/2, a typical value for tblen is about five times 
% the constraint length of the code (here, K = 7). 
tb = 7*5;
ConvCodeRate = 1/2;       % 1/2, 2/3
InterleaveBits = 1;

% training define
% short training for CFO estimation (NumSymbols = 52)
ShortTrain = sqrt(13/6)*[0 0 1+j 0 0 0 -1-j 0 0 0 1+j 0 0 0 -1-j 0 0 0 -1-j 0 ...
 0 0 1+j 0 0 0 0 0 0 -1-j 0 0 0 -1-j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0].';
NumShortTrainBlks = 10;
NumShortComBlks = 16*NumShortTrainBlks/blocklen;

% long training for channel estimation and SFO estimation (NumSymbols = 52)
LongTrain = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 ...
      1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1].';
NumLongTrainBlks = 2;
NumTrainBlks = NumShortComBlks + NumLongTrainBlks;

% Preamble generation
short_train = tx_freqd_to_timed(ShortTrain);
%plot(abs(short_train));
short_train_blk = short_train(1:16);
short_train_blks = repmat(short_train_blk,NumShortTrainBlks,1);

long_train = tx_freqd_to_timed(LongTrain);
long_train_syms = [long_train(fftlen-2*gilen+1:fftlen,:); long_train; long_train];
preamble = [short_train_blks; long_train_syms];

% packet information
NumBitsPerBlk = 48*ml*ConvCodeRate;
NumBlksPerPkt = 50;
NumBitsPerPkt = NumBitsPerBlk*NumBlksPerPkt;
NumPkts = 250;

% channel
CFO = 0*fs/fftlen
h = zeros(gilen,1);
h(1) = 1; 
%h(2) = 0.4; h(3)=0.3; h(4)=0.1;
h = h/norm(h);
channel = fft(h, 64);
channel([33:64 1:32]) = channel;
channel = channel([7:32 34:59]);

% timing parameters
RxTimingOffset = -3;
ExtraNoiseSamples = 500;

%% ************** Loop start***************************
snr = 5:5:20;
ber = zeros(1,length(snr));
per = zeros(1,length(snr));
for snr_index = 1:length(snr)
    num_err = 0;
    err = zeros(1,NumPkts);
    for pkt_index = 1:NumPkts
        [snr_index pkt_index]
%% *********************** Transmitter ******************************
        % Generate the information bits
        inf_bits = randn(1,NumBitsPerPkt)>0;
        CodedSeq = convenc(inf_bits,trellis);
        if InterleaveBits
           rdy_to_mod_bits = tx_interleaver(CodedSeq,48, ml);
        else
           rdy_to_mod_bits = CodedSeq;
        end
        
        %Modulate
        paradata = reshape(rdy_to_mod_bits,length(rdy_to_mod_bits)/ml,ml);
        ModedSeq = qammod(bi2de(paradata),2^ml)/NormFactor;
        
        mod_ofdm_syms = zeros(52, NumBlksPerPkt);
        mod_ofdm_syms(DataSubcPatt,:) = reshape(ModedSeq, 48, NumBlksPerPkt);
        mod_ofdm_syms(PilotSubcPatt,:) = 1;
        
        tx_blks = tx_freqd_to_timed(mod_ofdm_syms);
        
        % Guard interval insertion
        tx_frames = [tx_blks(fftlen-gilen+1:fftlen,:); tx_blks];
        % P/S
        tx_seq = reshape(tx_frames,NumBlksPerPkt*blocklen,1);
        tx = [preamble;tx_seq];
        
%% ****************************** Channel****************************
        FadedSignal = filter(h,1,tx);
        %rx_niosed = awgn(FadedSignal,snr(snr_index),'measured');
        len = length(FadedSignal);
        noise_var = 1/(10^(snr(snr_index)/10))/2;
        noise = sqrt(noise_var) * (randn(len,1) + j*randn(len,1));
        % add noise
        rx_signal = FadedSignal + noise;
        rx_signal = FadedSignal;
        
        % extra noise samples are inserted before the packet to test the packet search algorithm
        extra_noise = sqrt(noise_var) * (randn(ExtraNoiseSamples,1) + j*randn(ExtraNoiseSamples,1));
        % end noise is added to prevent simulation from crashing from incorrect timing in receiver
        end_noise = sqrt(noise_var) * (randn(170,1) + j*randn(170,1));
        
        rx = [extra_noise; rx_signal; end_noise];
        
        % introduce CFO
        total_length = length(rx);
        t = [0:total_length-1]/fs;
        phase_shift = exp(j*2*pi*CFO*t).';
        rx = rx.*phase_shift;

%% *************************  Receiver  ****************************
        %packet search
        rx_signal = rx_find_packet_edge(rx);
        
        % CFO coarse estimation and correction
        rx_signal = rx_frequency_sync(rx_signal,fs);
        
        % Fine time synchronization
        fine_time_est = rx_fine_time_sync(rx_signal, long_train);

        % Time synchronized signal
        sync_time_signal = rx_signal(fine_time_est:length(rx_signal));
        expected_length = 64*2+80*NumBlksPerPkt;
        [freq_tr_syms, freq_data_syms, freq_pilot_syms] = rx_timed_to_freqd(sync_time_signal(1:expected_length));     
        
        channel_est = mean(freq_tr_syms,2).*conj(LongTrain);  
        
        Data_seq = reshape(freq_data_syms,48*NumBlksPerPkt,1);
        
        % To see the effect of CFO-correction
        %scatterplot(Data_seq);title('After correction');
        
        % demodulate
        DemodSeq = de2bi(qamdemod(Data_seq*NormFactor,2^ml),ml);
        SerialBits = reshape(DemodSeq,size(DemodSeq,1)*ml,1).';
        
        if InterleaveBits
           deint_bits = rx_deinterleave(SerialBits, 48, ml);
        else
           deint_bits = SerialBits;
        end
        
        % Viterbi decoding
        DecodedBits = vitdec(deint_bits(1:length(CodedSeq)),trellis,tb,'trunc','hard');
        % Error calculation
        err(pkt_index) = sum(abs(DecodedBits-inf_bits));
        num_err = num_err + err(pkt_index);
    end
    ber(snr_index) = num_err/(NumPkts*NumBitsPerPkt);
    per(snr_index) = length(find(err~=0))/NumPkts;
end

%% display SNR-BER
semilogy(snr,ber,'-b.');hold on;
semilogy(snr,per,'-b.');