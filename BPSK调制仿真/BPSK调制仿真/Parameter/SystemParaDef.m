function sys_param = SystemParaDef()

%%系统类参数定义sys_param

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


