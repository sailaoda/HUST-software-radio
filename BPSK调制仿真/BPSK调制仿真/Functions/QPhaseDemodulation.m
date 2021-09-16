function output_signal = QPhaseDemodulation(input_signal,sys_param)

% 获取输入信号的长度
signal_len = length(input_signal);
t_i = 1:signal_len;
% 产生Q路相关解调信号cos(wt)
Q_t = cos(2*pi*sys_param.carrier_freq/sys_param.sample_freq*t_i);
 
% Q路信号混频 x(t)*cos(wt)
s_t = input_signal.*Q_t;

output_signal = LowPassFilter(s_t,2*sys_param.band/sys_param.sample_freq);
