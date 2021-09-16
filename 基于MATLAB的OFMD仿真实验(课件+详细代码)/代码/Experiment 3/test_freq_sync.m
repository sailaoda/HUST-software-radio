%% ************** Preparation part ********************
clear all; clc;
% system parameters
fs = 20e6;                  % 采样频率
gi = 1/4;                   % Guard interval factor
fftlen = 64;                % FFT长度 = 64 points
gilen = gi*fftlen;          % GI长度 = 16 points

% 训练序列
ShortTrain = sqrt(13/6)*[0 0 1+j 0 0 0 -1-j 0 0 0 1+j 0 0 0 -1-j 0 0 0 -1-j 0 ...
 0 0 1+j 0 0 0 0 0 0 -1-j 0 0 0 -1-j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0].';
NumShortTrainBlks = 10;     % 短训练序列符号数 = 10

short_train = tx_freqd_to_timed(ShortTrain);    % 把短训练序列从频域转换到时域
%plot(abs(short_train));
short_train_blk = short_train(1:16);    % 每个短训练序列长度16
short_train_blks = repmat(short_train_blk,NumShortTrainBlks,1);    % 共10个短训练序列--长度10*16=160



LongTrain = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 ...
      1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1].';   %注意，这里转置了
NumLongTrainBlks = 2;   % 长训练序列符号数 = 2

long_train = tx_freqd_to_timed(LongTrain);  % 64*1
long_train_syms = [long_train(fftlen-2*gilen+1:fftlen,:); long_train; long_train];  
% (64-2*16+1 = 33)  33:64共32个       
% 第一列前32个、第二列全64个、第三列全64个 -- 整体为 160*1
% 分别用于 GI2、T1、T2

%% ************** channel ***************************
% 定义多径信道
h = zeros(gilen,1);    % 3径传输
h(1) = 1;
h(5) = 0.5;
h(10) = 0.3;
cfo = 0.1*fs/fftlen;   % 载波频率偏移     cfo为什么这样设置来着？
%% ************** Loop start***************************
snr = 5:5:20;   % SNR = 5、10、15、20            (1,4)
mse = zeros(1,length(snr));   % MSE0值初始化     (1,4)
pkt_num = 2000;     % 数量为2000

for snr_idx = 1:length(snr)    % 测试4个snr值观测点的频偏估计误差MSE
    %snr_idx   % 用于及时跟踪输出id
    est_err = zeros(1,pkt_num);   % 0值初始化频偏估计误差 (1,1000)
    
    for pkt_idx = 1:pkt_num    % 1-2000
        % transmitter
        tx = [short_train_blks; long_train_syms];

        % channel
        rx_signal = filter(h,1,tx);     % (320,1)
        noise_var = 1/(10^(snr(snr_idx)/10))/2;
        len = length(rx_signal);

        noise = sqrt(noise_var) * (randn(len,1) + j*randn(len,1));
        
        % add noise
        rx_signal = rx_signal + noise;
        
        % add CFO ===============================
        total_length = length(rx_signal);   % 320
        t = [0:total_length-1]/fs;  % (1,320)
        
        phase_shift = exp(j*2*pi*cfo*t).';  % 加频偏指数
        rx_signal = rx_signal.*phase_shift;

        % receiver
        % for the dirty samples at the beginning (and synch errors in practical system)
        pkt_det_offset = 30;    % 包检测偏移？？
        % averaging length
        rlen = length(short_train_blks) - pkt_det_offset;  % 160 - 30 = 130
        
        % short training symbol periodicity
        D = 16;
        
        % 一次性计算所有相邻符号相关性(115,1)      30-144 .* 46-160    
        phase = rx_signal(pkt_det_offset:pkt_det_offset+rlen-D).* ...   % 30 : 30+130-16
                conj(rx_signal(pkt_det_offset+D:pkt_det_offset+rlen));  % 30+16 : 30+130
        % add all estimates 
        phase = sum(phase);
        
        % 频偏估计  CFO Estimation
        freq_est = -angle(phase) / (2*pi*D/fs);
        % 频偏估计误差计算
        est_err(pkt_idx) = (freq_est - cfo)/cfo;  % (1,2000)

%         radians_per_sample = 2*pi*freq_est/fs;
%         time_base = 0:length(rx_signal)-1;
%         correction = exp(-j*(radians_per_sample)*time_base);             
%         out_signal = rx_signal.*correction.';
    end
    mse(snr_idx) = mean(abs(est_err).^2);   % (1,4)
end

semilogy(snr,mse);
xlabel('SNR/dB');
ylabel('MSE');