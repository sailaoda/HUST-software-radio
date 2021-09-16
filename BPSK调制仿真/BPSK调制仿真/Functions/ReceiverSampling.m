function sampled_signal = ReceiverSampling(orignal_signal,sys_param)

% 采样的比例(每间隔sampling_ratio个点采样一个)
sampling_ratio = sys_param.sim_freq/sys_param.sample_freq;

% 数据的总点数
data_len = length(orignal_signal);
%采样后的点数
sampled_len = floor(data_len/sampling_ratio);
% 间隔采样
sample_location = 1 + 0:sampling_ratio:sampling_ratio*(sampled_len-1);
% 采样
sampled_signal = orignal_signal(sample_location);
