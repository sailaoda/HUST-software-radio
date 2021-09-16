clear all;
close all;
clc;

load data.mat            %% 读取原始采样数据
N = length(data);        %% 数据长度
fs = 16e6;               %% 原始采样率
Bw = 40e3;               %% 待提取信号带宽
f_Lo = 2e6;              %% 待提取信号中心频率

Power_xdBm(data(1:2^20),fs);  %画原始采样信号功率谱图，data为从data.mat中读出的原始采样数据
title('输入信号功率谱图 采样率16MHz 频谱分辨率15.259Hz');


%% NCO mixing 正交混频
Lo = exp( - 1j * 2 * pi * f_Lo * ( 0 : N - 1 ) / fs ); %% 用于正交混频的本振信号

mixing_data = data .* Lo;  

%% 第一级CIC滤波+抽取




%% HB1 Filter+2倍抽取



%% HB2 Filter+2倍抽取


%% 级联HB滤波器数量根据方案确定


%% 最后一级FIR滤波+抽取 



%% 画出每一级滤波器的幅频响应


%% 画输出信号功率谱，其中fir_data为最后一级滤波抽取输出数据，fs_out为最后一级输出数据采样率
Power_xdBm_complex(fir_data(1:4096),fs_out);  %
title('DDC输出信号功率谱图 采样率100kHz 频谱分辨率24.414Hz');
