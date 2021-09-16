clear
close all

%  系统参数定义
sys_param = Parameter();
M=16;
k=log2(M);
%  数据流长度
N=400;
%  输入的比特数据流
input_data = randi([0,1],1,N);

% 信号调制
modulated_signal = QAM_Modulation(input_data,sys_param);

%调制信号时域波形 前400个比特
figure
PlotTDSignal(modulated_signal(1:400),sys_param.sample_freq,sys_param.symbol_rate);
title('调制信号时域波形(前400个比特)');
% 调制信号频谱
figure
PlotFFTSignal(modulated_signal,sys_param.sample_freq);
title('调制信号频谱');

% 添加信道噪声
for j=1:10
signal_noise = awgn(modulated_signal,sys_param.SNR(j));

% 采用正交相干解调方式
[decode_data,I,Q] = QAM_Demodulation(signal_noise,sys_param);
 
% % 误码率曲线
error_ratio(j) = CalBitErrorRate(input_data,decode_data);
end
figure
semilogy(sys_param.SNR,error_ratio,'*-k');hold on;grid on;
xlabel('SNR/dB');
ylabel('误码率');
title('AWGN信道下的误码率');
% % 星座图
figure
plot(I,Q,'*');
title('解码后的星座图');
% % 
figure
subplot(2,1,1);
stem(input_data(1:200));
title('原始发送的二进制信号');
subplot(2,1,2);
stem(decode_data(1:200));
title('接收(解调)的二进制信号');

