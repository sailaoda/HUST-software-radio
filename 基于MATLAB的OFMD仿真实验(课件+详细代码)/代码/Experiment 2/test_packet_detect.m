%% ************** Preparation part ********************
clear all; clc;
% system parameters
gi = 1/4;                   % Guard interval factor
fftlen = 64;                % FFT长度 = 64 points
gilen = gi*fftlen;          % GI长度 =16 points

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
h = zeros(gilen,1);     % 3径传输
h(1) = 1;
h(5) = 0.5;
h(10) = 0.3;
start_noise_len = 500;      % 加的noise的终点
snr = 20;       % 信噪比20

%% ************** transmitter ***************************
tx = [short_train_blks; long_train_syms];    % 传输信号仅由长短序列构成，为320*1 (不含data)

%% ************** pass channel ***************************
rx_signal = filter(h, 1, tx);   % 接收多径传输信号     
noise_var = 1/(10^(snr/10))/2;  
len = length(rx_signal);        % 接收信号长度 = 320
noise = sqrt(noise_var) * (randn(len,1) + j*randn(len,1));   % 320*1

% add noise  
rx_signal = rx_signal + noise;  % 含噪声的接收信号
start_noise = sqrt(noise_var) * (randn(start_noise_len,1) + j*randn(start_noise_len,1)); 
rx_signal = [start_noise; rx_signal];       % 再加上500points长度的起始噪声在接收信号之前   整体为820*1


%% ************** receiver ***************************
search_win = 700;   % 搜索窗大小 (理论上大于噪声长度500就行) 
D = 16;   % 每个短训练序列符号ti长度 / the length of short training block: LTB

% Calculate the delayed correlation  一次性计算所有相邻符号相关性
delay_xcorr = rx_signal(1:search_win+2*D).*conj(rx_signal(1*D+1:search_win+3*D));  %732*1
% 1:700+2*16    .*    1*16+1:700+3*16        1;732 .* 17:748

% 注相邻短训练序列符号的相同点位置间隔为16(17-1=16)   LTB=D=16
% 相邻符号总长度则为16*2=32   (2*D)

% Moving average of the delayed correlation   计算所有相邻符号相关性mn(的分子|Cn|)
ma_delay_xcorr = abs(filter(ones(1,2*D), 1, delay_xcorr));   % 732*1
ma_delay_xcorr(1:2*D) = [];  % 从第33个开始算  *******


%改成for循环的写法：
ma_delay_xcorr_ss = zeros(700,1);
for i = 1:700
    counter = 0;
    for j = i : (i + 2*D - 1)                               % 2-33、3-34...700-731、701-732
        counter = counter + (delay_xcorr(j+1));              % 从最最初第33个开始算所以+1   ******
    end
    ma_delay_xcorr_ss(i) = abs(counter);
end



% Moving average of received power            计算所有相邻符号相关性mn(的分母Pn)
ma_rx_pwr = filter(ones(1,2*D), 1, abs(rx_signal(1*D+1:search_win+3*D)).^2);  % 732*1
ma_rx_pwr(1:2*D) = [];


% The decision variable                       
delay_len = length(ma_delay_xcorr);    % 732*1
ma_M = ma_delay_xcorr(1:delay_len)./ma_rx_pwr(1:delay_len);    % 一次性计算所有相邻符号相关性mn=|Cn|/Pn

% remove delay samples     移除前32个，因为前32个还未进入2*D = 32 长度的 filter ，计算相关性无意义
%ma_M(1:2*D) = [];    % 700*1

threshold = 0.75;   % 判决门限         (threshold = 0.95时，thres_idx = 501)
thres_idx = find(ma_M > threshold);  % 查询满足条件(相关性大于threshold)元素的位置thres_idx
 
if isempty(thres_idx)        % 判断有无检测到packet
  thres_idx = 1;        
else   
  thres_idx = thres_idx(1);   % 若有多个thres_idx均满足条件，则取第一个作为检测到packet的起始点
end

detected_packet = rx_signal(thres_idx:length(rx_signal));    % 根据索引取出detected packet