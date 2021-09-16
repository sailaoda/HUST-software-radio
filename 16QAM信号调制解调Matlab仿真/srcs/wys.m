clear all;
close all;
clc;
%%系统类参数定义sys_param

%参量定义
MES_LEN=4*10000; % source message length
SYM_LEN=MES_LEN/4;% symbol length
INSERT_TIMES=8; %insert times befor filter
PETAL=5; %num of petals each side of filter
BETA=0.5; %filter bandwidth
SELECT=2; %mode slect

% 射频信号的中心频率
sys_param.center_freq  = 2.4e9;
% 信号相对于中心的载波频率
sys_param.carrier_freq = 200e3;
% 信号比特速率
sys_param.symbol_rate = 100e3;


% 基带信号采样频率
sys_param.sample_freq = 800e3;
% 信号发送带宽
sys_param.band = 150e3;

% 仿真的信噪比(dB)
sys_param.SNR = 20;

% 一个比特的时间长度
sys_param.bit_duration = 1/sys_param.symbol_rate;
% 采样时间间隔
sys_param.sampling_interval = 1/sys_param.sample_freq;

%  输入的数据流
input_data = [0 1 0 0 1 0 1 1 0 0 1];
%input_data = [0 1 0 0 1 0 1 1 0 0 1 1 1 0 0 1 0 1 0 1 0 0 1 1 1 0 0 1 0 1 1 0 1 0 1 0 0 1 0 1 1 0 0 1 1 1 0 0 1 0 1 0 1 0 0 1 1 1 0 0];
%input_data = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];


%产生调制信号
[signal_sendI,signal_sendQ,message,signal_base_band]=Modulation(MES_LEN,SYM_LEN,INSERT_TIMES,PETAL,BETA);

%加高斯白噪声
[signal_receiveI,signal_receiveQ]=AddNoise(signal_sendI,signal_sendQ,SNR,INSERT_TIMES);

%接收机解调
[mymessage,mysignal_base_band]=Receiver(signal_receiveI,signal_receiveQ,INSERT_TIMES,MES_LEN,SYM_LEN,BETA,PETAL);
