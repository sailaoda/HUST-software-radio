%% ************** Preparation part ********************
clear all; clc;

% 系统参数
fs = 8e6;                    % 抽样频率
ml = 2;                      % 调制阶数 = 2 —— QPSK调制
NormFactor = sqrt(2/3*(ml.^2-1));
gi = 1/4;                    % 保护间隔比例 = 1/4
fftlen = 64;                 % FFT长度 = 64 points/chips
gilen = gi*fftlen;           % 保护间隔/循环前缀长度 = 16 points/chips
blocklen = fftlen + gilen;   % OFDM符号长度 = 80 points/chips


% 子载波标号
DataSubcPatt = [1:5 7:19 21:26 27:32 34:46 48:52]'; % 数据子载波位置标号
PilotSubcPatt = [6 20 33 47]; % 导频子载波位置标号
UsedSubcIdx = [7:32 34:59]; % 共用52个子载波


% 信道编码参数
trellis = poly2trellis(7,[133 171]); % 卷积码
tb = 7*5;
ConvCodeRate = 1/2;       % 码率 = 1/2


% 训练序列
% 短训练序列 (NumSymbols = 52)
ShortTrain = sqrt(13/6) * [0 0 1+j 0 0 0 -1-j 0 0 0 1+j 0 0 0 -1-j ...
                       0 0 0 -1-j 0 0 0 1+j 0 0 0 0 0 0 -1-j 0 0 0 ...
                       -1-j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0].';
NumShortTrainBlks = 10;     % 短训练序列符号数 = 10
NumShortComBlks = 16*NumShortTrainBlks/blocklen;    % 160/80=2

% 长训练序列 (NumSymbols = 52)
LongTrain = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1  ...
     1 1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1].';
NumLongTrainBlks = 2;       % 长训练序列符号数 = 2
%短训练序列加长训练序列共相当于4个OFDM符号
NumTrainBlks = NumShortComBlks + NumLongTrainBlks; 

short_train = tx_freqd_to_timed(ShortTrain);   % 把短训练序列从频域转换到时域
%plot(abs(short_train));
short_train_blk = short_train(1:16);    % 每个短训练序列长度16
% 共10个短训练序列 -- 总长度为10*16=160
short_train_blks = repmat(short_train_blk,NumShortTrainBlks,1);  

long_train = tx_freqd_to_timed(LongTrain);     % 把长训练序列从频域转换到时域
long_train_syms = [long_train(fftlen-2*gilen+1:fftlen,:);      % 加循环前缀
                   long_train; long_train];
 % 构成前导训练序列
preamble = [short_train_blks; long_train_syms]; 


% 包信息
NumBitsPerBlk = 48*ml*ConvCodeRate;    
% 每个OFDM符号信息量=48个*2(调制阶数，每个数2bit信息)*卷积码效率
NumBlksPerPkt = 50;        % 每个包符号数50
NumBitsPerPkt = NumBitsPerBlk*NumBlksPerPkt;      % 每个包信息量位50*48
NumPkts = 250;             % 总包数250

% 信道与频偏参数
h = zeros(gilen,1);  % 定义多径信道
h(1) = 1; h(3) = 0.5; h(5) = 0.2;   % 3径
h = h/norm(h);
CFO = 0.1*fs/fftlen;    % 频偏

% 定时参数
ExtraNoiseSamples = 500;   % 包前加额外500长度的噪声

%% ************** Loop start*************************************
snr = 0:1:20;                   % 用于检测的信噪比值
ber = zeros(1,length(snr));     % 0值初始化误码率
per = zeros(1,length(snr));     % 0值初始化误包率

for snr_index = 1:length(snr)  
    num_err = 0;
    err = zeros(1,NumPkts);
    for pkt_index = 1:NumPkts   % 250个包

%% *********************** Transmitter **************************
        % 生成信息序列
        inf_bits = randn(1,NumBitsPerPkt)>0;     % 生成48*50个信息比特
        CodedSeq = convenc(inf_bits,trellis);    % 卷积编码
        
        % 调制
        paradata = reshape(CodedSeq,length(CodedSeq)/ml,ml); % 分为两路：
        ModedSeq = qammod(bi2de(paradata),2^ml)/NormFactor;  % 4QAM调制
        
        mod_ofdm_syms = zeros(52, NumBlksPerPkt); 
        mod_ofdm_syms(DataSubcPatt,:) = reshape(ModedSeq,48,NumBlksPerPkt);
        %调制后信号48行50列对应子载波id [1:5 7:19 21:26 27:32 34:46 48:52]';
        mod_ofdm_syms(PilotSubcPatt,:) = 1; % 加导频
        
        % 对OFDM符号做Mapping及IFFT（输出64行50列）
        tx_blks = tx_freqd_to_timed(mod_ofdm_syms);
        
        % 加循环前缀
        % 每个OFDM符号后16位重复放在前面做cp
        tx_frames = [tx_blks(fftlen-gilen+1:fftlen,:); tx_blks];
        
        % 并串转换
        tx_seq = reshape(tx_frames,NumBlksPerPkt*blocklen,1);   % 50*80
        tx = [preamble;tx_seq];     % 在50个OFDM符号前加前导序列，构成一个包
        
%% ****************************** Channel************************
        FadedSignal = filter(h,1,tx);     % 包通过多径信道
        len = length(FadedSignal);
        noise_var = 1/(10^(snr(snr_index)/10))/2;
        noise = sqrt(noise_var) * (randn(len,1) + j*randn(len,1));
        % 加噪声
        rx_signal = FadedSignal + noise; 
        %包前侧加500长度的噪声
        extra_noise = sqrt(noise_var) * (randn(ExtraNoiseSamples,1) +  ...
                      j*randn(ExtraNoiseSamples,1));  
        %包后侧加170长度的噪声
        end_noise = sqrt(noise_var) * (randn(170,1) + j*randn(170,1));  
        
        % 接收信号
        rx = [extra_noise; rx_signal; end_noise]; 
        
        % 引入频偏
        total_length = length(rx);   % 计算接收信号长度
        t = [0:total_length-1]/fs;
        phase_shift = exp(j*2*pi*CFO*t).';    % 加载波频率偏移
        rx = rx.*phase_shift;

%% *************************  Receiver  *************************
        % 包检测
        %rx_signal去掉包前噪声的接收信号,pkt_offset包前噪声的偏移量
        rx_signal = test_rx_find_packet_edge(rx);
        
        % 频偏估计与纠正
        %rx_signal补偿频率偏移后的接收信号,cfo_est频率偏移量
        rx_signal = frequencysync(rx_signal,fs);
        
        % 时间精同步
        % 时间同步位置
        fine_time_est = finetimesync(rx_signal, long_train);
        % Time synchronized signal
        % 期望去掉短训练序列及长序列前cp后，
        % 得到长度即长训练序列64*2个+80*50个OFDM符号
        expected_length = 64*2+80*NumBlksPerPkt;
        % 去掉短训练序列以及长序列前cp
        fine_time_est_end = fine_time_est+expected_length-1;
        sync_time_signal = rx_signal(fine_time_est:fine_time_est_end);
        
        [freq_tr_syms, freq_data_syms, freq_pilot_syms] = ...
                                       rx_timed_to_freqd(sync_time_signal);   
        % freq_tr_syms取出长训练序列48行n_data_syms列
        % freq_data_syms取出信息48行n_data_syms列
        % freq_pilot_syms取出导频4行n_data_syms列
        
        % 信道估计
        % 接收longtrain freq_tr_syms取行！
        % 平均 H(k) = freq_tr_syms * conj(LongTrainingSyms)  
        channel_est = mean(freq_tr_syms,2).*conj(LongTrain);       
        
        % Data symbols channel correction
        % 扩展信息序列对应的H(k)，同接收OFDM符号个数相同
        chan_corr_mat = repmat(channel_est(DataSubcPatt), ...
                               1, size(freq_data_syms,2));
        % 用估计的H(k)共轭乘接受信息序列，得到估计的发送信息序列                   
        freq_data_syms = freq_data_syms.*conj(chan_corr_mat);
        % 对导频部分做同样的处理
        chan_corr_mat = repmat(channel_est(PilotSubcPatt), ...
                               1, size(freq_pilot_syms,2));
        freq_pilot_syms = freq_pilot_syms.*conj(chan_corr_mat);

        % 幅度归一化
        % 信息序列对应的H(k)绝对值平方行求和
        chan_sq_amplitude = sum(abs(channel_est(DataSubcPatt,:)).^2, 2);
        %扩展至估计的发送信息序列列数
        chan_sq_amplitude_mtx = repmat(chan_sq_amplitude, ...
                                       1, size(freq_data_syms,2));
        data_syms_out = freq_data_syms./chan_sq_amplitude_mtx;  % 幅度归一化 
       
        % 对导频序列做同样处理
        chan_sq_amplitude = sum(abs(channel_est(PilotSubcPatt,:)).^2, 2);
        chan_sq_amplitude_mtx = repmat(chan_sq_amplitude, ...
                                       1, size(freq_pilot_syms,2));
        pilot_syms_out = freq_pilot_syms./chan_sq_amplitude_mtx;

        phase_est = angle(sum(pilot_syms_out)); % 计算导频
        phase_comp = exp(-j*phase_est);
        data_syms_out = data_syms_out.*repmat(phase_comp, 48, 1);

        Data_seq = reshape(data_syms_out,48*NumBlksPerPkt,1); % 48*50
        
        % 解调
        DemodSeq = de2bi(qamdemod(Data_seq*NormFactor,2^ml),ml);  
        deint_bits = reshape(DemodSeq,size(DemodSeq,1)*ml,1).';
        
        % 卷积码译码
        DecodedBits = vitdec(deint_bits(1:length(CodedSeq)), ...
                             trellis,tb,'trunc','hard');  % 维特比译码
        % 误差计算
        err(pkt_index) = sum(abs(DecodedBits-inf_bits)); % 计算误码个数
        num_err = num_err + err(pkt_index);
    end
    ber(snr_index) = num_err/(NumPkts*NumBitsPerPkt);   % 误码率
    per(snr_index) = length(find(err~=0))/NumPkts;  % 误包率
end

%% 绘制 SNR-BER 和 SNR-PER曲线
semilogy(snr,ber,'-b.');
hold on;
semilogy(snr,per,'-re');
xlabel('SNR (dB)');
ylabel('ERROE');
grid on;
legend('BER','PER')

