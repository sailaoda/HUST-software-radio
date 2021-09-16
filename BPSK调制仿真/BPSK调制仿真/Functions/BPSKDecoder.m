function decode_data = BPSKDecoder(x,sys_param)


% 解码BPSK调制数据
% 数据长度
data_len = length(x);
% 数据流的比特数量
bit_num = floor(data_len/sys_param.sample_freq*sys_param.symbol_rate);
% 一个比特的采样点数量
bit_interval_num = floor(sys_param.sample_freq/sys_param.symbol_rate);
% 初始化
decode_data = zeros(1,bit_num);

for k = 1:bit_num
    % 第k个比特的采样点
    sample_points = x([1+(k-1)*bit_interval_num:k*bit_interval_num-1]);
    % 去采样点的平均值
    average_value = mean(sample_points);
    % 如果大于0则为1,如果小于0则为0
    if average_value > 0
        decode_data(k) = 1;
    end
    if average_value < 0
        decode_data(k) = 0;
    end
    
end