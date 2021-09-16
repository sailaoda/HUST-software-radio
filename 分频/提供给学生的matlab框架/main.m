clear;
close all;
clc;

load data.mat            %% 读取原始采样数据
N = length(data);        %% 数据长度
fs = 16e6;               %% 原始采样率
Bw = 40e3;               %% 待提取信号带宽
f_Lo = 2e6;              %% 待提取信号中心频率

Power_xdBm_complex(data(1:2^20),fs);  %画原始采样信号功率谱图，data为从data.mat中读出的原始采样数据
title('输入信号功率谱图 采样率16MHz 频谱分辨率15.259Hz');
%% NCO mixing 正交混频
Lo = exp( - 1j * 2 * pi * f_Lo * ( 0 : N - 1 ) / fs ); %% 用于正交混频的本振信号
mixing_data = data .* Lo;
%% 第一级CIC滤波+抽取
N = 5;
fs1 = fs/N;
cic_data = cic_filter(N,fs,mixing_data,1);
cic_data = cic_data(N+1:N:end);
Power_xdBm_complex(cic_data,fs1);  %画CIC滤波后信号功率谱图
title(['CIC输出信号功率谱图 采样率是    ',num2str(fs1/10^6),'MHz 频谱分辨率15.259Hz']);
%% HB1 Filter+2倍抽取
fpass1 = 0.5e6;
fstop1 = fs1/2 - fpass1;
rs1 = 40;rp1 = 40;
fs2 = fs1/2;
HB_data1 = hb_filter(fs1,fpass1,fstop1,rs1,rp1,cic_data,1);
HB_data1 = HB_data1(1:2:end);
Power_xdBm_complex(HB_data1,fs2);  %画HB1信号功率谱图
title(['HB1输出信号功率谱图 采样率是    ',num2str(fs2/10^6),'MHz 频谱分辨率15.259Hz']);
%% HB2 Filter+2倍抽取
fpass2 = 3e5;
fstop2 = fs2/2 - fpass2;
rs2 = 40;rp2 = 40;
% rs2 = 0.01;rp2 = 0.01;
fs3 = fs2/2;
HB_data2 = hb_filter(fs2,fpass2,fstop2,rs2,rp2,HB_data1,1);
HB_data2 = HB_data2(1:2:end);
Power_xdBm_complex(HB_data2,fs3);  %画HB1信号功率谱图
title(['HB2输出信号功率谱图 采样率是    ',num2str(fs3/10^6),'MHz 频谱分辨率15.259Hz']);
%% 级联HB滤波器数量根据方案确定
fpass3 = 1.5e5;
fstop3 = fs3/2 - fpass3;
rs3 = 40;rp3 = 40;
% rs3 = 0.01;rp3 = 0.01;
fs4 = fs3/2;
HB_data3 = hb_filter(fs3,fpass3,fstop3,rs3,rp3,HB_data2,1);
HB_data3 = HB_data3(1:2:end);
Power_xdBm_complex(HB_data3,fs4);  %画HB1信号功率谱图
title(['HB3输出信号功率谱图 采样率是    ',num2str(fs4/10^6),'MHz 频谱分辨率15.259Hz']);

fpass4 = 0.75e5;
fstop4 = fs4/2 - fpass4;
rs4 = 40;rp4 = 40;
% rs4 = 0.01;rp4 = 0.01;
fs5 = fs4/2;
HB_data4 = hb_filter(fs4,fpass4,fstop4,rs4,rp4,HB_data3,1);
HB_data4 = HB_data4(1:2:end);
Power_xdBm_complex(HB_data4,fs5);  %画HB1信号功率谱图
title(['HB4输出信号功率谱图 采样率是   ',num2str(fs5/10^6),'MHz 频谱分辨率15.259Hz']);

fpass5 = 0.4e5;
fstop5 = fs5/2 - fpass5;
rs5 = 40;rp5 = 40;
% rs5 = 0.01;rp5 = 0.01;
fs6 = fs5/2;
HB_data5 = hb_filter(fs5,fpass5,fstop5,rs5,rp5,HB_data4,1);
HB_data5 = HB_data5(1:2:end);
Power_xdBm_complex(HB_data5,fs6);  %画HB1信号功率谱图
title(['HB5输出信号功率谱图 采样率是    ',num2str(fs6/10^6),'MHz 频谱分辨率15.259Hz']);
%% 最后一级FIR滤波+抽取
fpass = 2e4;
fstop = 3e4;
% rs5 = 40;rp5 = 40;
rs = 0.000001;rp = 0.1;
fir_data = fir_filter(fs6,fpass,fstop,rs,rp,HB_data5,1);
Power_xdBm_complex(fir_data,fs6);  %画HB1信号功率谱图
title(['FIR输出信号功率谱图 采样率是    ',num2str(fs6/10^6),'MHz 频谱分辨率15.259Hz']);
fs_out = fs6;
%% 画出每一级滤波器的幅频响应
%% 画输出信号功率谱，其中fir_data为最后一级滤波抽取输出数据，fs_out为最后一级输出数据采样率
Power_xdBm_complex(fir_data(1:4096),fs_out);  %
title('DDC输出信号功率谱图 采样率是    100kHz 频谱分辨率24.414Hz');
