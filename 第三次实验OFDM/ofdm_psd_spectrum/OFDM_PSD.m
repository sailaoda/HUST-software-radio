% OFDM基带系统
clc;clear all;close all;
% 参数设置
N = 128;%ifft 点数
num_carriers = 64;%载波数
M = 4;%QPSK
m = 1024;%快速傅里叶变换
length_symbol = 100;%符号长度
total = num_carriers*length_symbol;%总符号数
% 产生基带数据信号
sig = randi(1,total,[0 3]);
% QPSK调制
sig_mod = pskmod(sig,M);
% 串并转换
sig_s = reshape(sig_mod,num_carriers,length_symbol);
% 功率谱插值
sid_0= [sig_s(1:num_carriers/2,:);
zeros(N-num_carriers,length_symbol);
sig_s(num_carriers/2+1:num_carriers,:)];
% Ifft
sig_tx = ifft(sid_0,N);
% 求功率谱
Sf = fftshift(fft(sig_tx,m));
OFDM_Sig_PSD=10*log10(abs(Sf).^2/max(abs(Sf).^2));
f = (0:length(OFDM_Sig_PSD)-1)/length(OFDM_Sig_PSD);%归一化频率
plot(f,OFDM_Sig_PSD);
hold on;
axis([0 1 -40 0]);
xlabel('归一化频率');ylabel('归一化功率谱');title('OFDM功率谱')
