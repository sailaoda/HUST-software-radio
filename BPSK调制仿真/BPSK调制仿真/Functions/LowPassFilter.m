function y = LowPassFilter(x,ratio)

% 低通滤波器
% x 输入数据
% 数据的最高频率
% 滤波器的截止频率

len = length(x);
fft_x = fft(x);

stop_point = round(len/2*ratio);

fft_x(stop_point:len-stop_point+2) = zeros(1,len-2*stop_point+3);

y = ifft(fft_x);
