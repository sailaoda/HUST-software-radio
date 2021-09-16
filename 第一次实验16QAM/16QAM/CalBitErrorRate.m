function error_ratio= CalBitErrorRate(input_data,decode_data)

% 计算误码率
% 获取数据长度
data_len = length(input_data);
% 初始化计数器
count = 0;

for k = 1:data_len
    % 如果解码错误
    if input_data(k)~=decode_data(k)
        % 计数器加1
        count = count +1;
    end
end

error_ratio = count/data_len;

    