function modulated_signal = BPSKMudulation(input,sys_param)

% 获取数据长度
len = length(input);
% 一个比特的长度(点数)
symbol_len = sys_param.sample_freq/sys_param.symbol_rate;
% 初始化
modulated_signal = [];
% 离散时间点
t_i = 1:symbol_len;
% 获得符号表达
for k = 1:len
    if input(k) == 1
        bit_representation =  cos(2*pi*sys_param.carrier_freq/sys_param.sample_freq*t_i);
    end
    if input(k) == 0
        bit_representation = -cos(2*pi*sys_param.carrier_freq/sys_param.sample_freq*t_i);
    end
    modulated_signal = [modulated_signal bit_representation];
end
    
%modulated_signal = LowPassFilter(modulated_signal,1/sys_param.sampling_interval/2,sys_param.band);
% 截止频率比例

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    


