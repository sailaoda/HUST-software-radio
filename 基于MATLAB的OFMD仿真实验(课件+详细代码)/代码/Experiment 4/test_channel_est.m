%% ************** Preparation part ********************
clear all; clc;
% system parameters
ml = 2;                      % Modulation level: 2          QPSK调制
NormFactor = sqrt(2/3*(ml.^2-1));
gi = 1/4;                    % GI factor
fftlen = 64;
gilen = gi*fftlen;           % Length of GI = 16
blocklen = fftlen + gilen;   % Length of OFDM symbol = 80

% index define
UsedSubcIdx = [7:32 34:59];
reorder = [33:64 1:32];

% long training for channel estimation and SFO estimation (NumSymbols = 52)
LongTrain = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 ...
      1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1].';  % 注：这里转置了 (52,1)
NumLongTrainBlks = 2;   % 长训练序列符号数 = 2

long_train = tx_freqd_to_timed(LongTrain);    % IFFT (64,1)
long_train_syms = [long_train(fftlen-2*gilen+1:fftlen,:); long_train; long_train];
% (64-2*16+1 = 33)  33:64共32个复制到最前用作GI       
% 第一列前32个、第二列全64个、第三列全64个 -- 整体为(160,1)
% 分别用于 GI2、T1、T2
%% ************** channel ***************************
h = zeros(gilen,1);   % 定义多径信道(16,1)    % 3径传输
h(1) = 1;
h(5) = 0.5;
h(10) = 0.3;
channel = fft(h, 64);      % 64点FFT频域信道 (64,1)
channel(reorder) = channel;     % 前后换位  (64,1)     % reorder = [33:64 1:32];
channel = channel(UsedSubcIdx);    % 取所用子载波位置的信道 (52,1)

%% ************** Loop start***************************
snr = 0:2:20;     % 信噪比观测点位：0、2、4......18、20  共11个      先验信噪比
mse = zeros(1,length(snr));    % 0值初始化11个计算信道估计误差(MSE)点
pkt_num = 1000;     % 数量为1000

% 获取接收信号
tx = long_train_syms;   % 获取长训练符号作发送信号 (160,1)
rx = filter(h,1,tx);    % 经过多径信道，接收信号
len = length(rx);       % 接收信号长度160    


for snr_idx = 1:length(snr)     % 测试11个snr值观测点的信道估计误差MSE
    err_est = zeros(1, pkt_num);    % 0值初始化信道估计误差 (1,1000)
    
    for pkt_idx = 1:pkt_num     % 1-1000
        % 获取初始接收信号
        rx_signal =  rx; 
        
        % 添加加性噪声       SNR=10 lg(S/N)      S/N=10^(SNR/10)     1/.../2 为什么
        noise_var = 1/(10^(snr(snr_idx)/10))/2;     % 噪声方差    
        noise = sqrt(noise_var) * (randn(len,1) + j*randn(len,1));  % 生成随机加性噪声(160,1)
        rx_signal = rx_signal + noise;     % 添加加性噪声 (160,1)
        
        % 去除保护间隔
        long_tr_syms = rx_signal(33:end);      % 去除GI2 (128,1)
        long_tr_syms = reshape(long_tr_syms, 64, 2);   % (64,2)

        % to frequency domain
        freq_long_tr = fft(long_tr_syms)/(64/sqrt(52));   % FFT+功率归一化 (64,2)
        freq_long_tr(reorder,:) = freq_long_tr;     % reorder = [33:64 1:32]
        freq_tr_syms = freq_long_tr(UsedSubcIdx,:);     % (52,2)

        % 信道估计 + 估计误差计算
        channel_est = mean(freq_tr_syms,2).*conj(LongTrain); % H(k) = freq_tr_syms * conj(LongTrainingSyms)
        %err_est(pkt_idx) = mean(abs(channel_est-channel).^2)/mean(abs(channel).^2); % 计算MSE  注意"/"的后半段
        err_est(pkt_idx) = mean(abs(channel_est-channel).^2); % 计算  以MSE来衡量信道估计的性能
    end
    % 以平均均方误差来衡量信道估计的性能
    mse(snr_idx) = mean(err_est);   % 对每个snr条件下，各1000个packet的est_err求平均
end


% 绘图
semilogy(snr,mse,'-o');
%title('');
xlabel('SNR (dB)');
ylabel('MSE');
grid on; 
