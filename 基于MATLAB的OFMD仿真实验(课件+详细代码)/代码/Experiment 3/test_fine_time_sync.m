%% ************** Preparation part ********************
clear all; clc;
% system parameters
gi = 1/4;                   % Guard interval: in the Brazil_E model,the maxmum delay is 2e-6s, equals to 16 points. 
fftlen = 64;
gilen = gi*fftlen;           % Length of guard interval (points)

% training sequence
ShortTrain = sqrt(13/6)*[0 0 1+j 0 0 0 -1-j 0 0 0 1+j 0 0 0 -1-j 0 0 0 -1-j 0 ...
 0 0 1+j 0 0 0 0 0 0 -1-j 0 0 0 -1-j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0].';
NumShortTrainBlks = 10;

short_train = tx_freqd_to_timed(ShortTrain);
%plot(abs(short_train));
short_train_blk = short_train(1:16);
short_train_blks = repmat(short_train_blk,NumShortTrainBlks,1);

LongTrain = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 ...
      1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1].';
NumLongTrainBlks = 2;

long_train = tx_freqd_to_timed(LongTrain);
long_train_syms = [long_train(fftlen-2*gilen+1:fftlen,:); long_train; long_train];

%% ************** channel ***************************
h = zeros(gilen,1);
h(1) = 1;
h(5) = 0.5;
h(10) = 0.3;
%% ************** Loop start***************************
snr = 10:5:10;   %ÐÞ¸Ä
mse = zeros(1,length(snr));
pkt_num = 1000;
ideal_start = 193;
for snr_idx = 1:length(snr)
    snr_idx
    est_err = zeros(1,pkt_num);
    for pkt_idx = 1:pkt_num
        %% transmitter
        tx = [short_train_blks; long_train_syms];

        %% channel
        rx_signal = filter(h,1,tx);
        noise_var = 1/(10^(snr(snr_idx)/10))/2;
        len = length(rx_signal);
        noise = sqrt(noise_var) * (randn(len,1) + j*randn(len,1));
        % add noise
        rx_signal = rx_signal + noise;

        %% receiver
        %timing search window size
        start_search=150;
        end_search=200;
        time_corr_long = zeros(1,end_search-start_search+1);

        for idx=start_search:end_search
            time_corr_long(idx-start_search+1) = sum((rx_signal(idx:idx+63).*conj(long_train)));
        end

        [max_corr,long_search_idx] = max(abs(time_corr_long));

        fine_time_est = start_search-1 + long_search_idx;
        err_est(pkt_idx) = fine_time_est - ideal_start;
    end
    mse(snr_idx) = mean(abs(err_est).^2);
end
semilogy(snr,mse);
xlabel('SNR/dB');
ylabel('MSE');