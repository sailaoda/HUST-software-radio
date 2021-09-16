function output_data = cic_filter(N, fs, input_data, flag)
%%% CIC抽取滤波器
%%% 输入
%       N：滤波器阶数，即抽取比
%       fs：采样频率
%       input_data：输入序列
%       flag：画图标志位
%%% 输出
%       output_data：滤波后的序列
b = zeros(1,N+1);b(1) = 1;b(N+1) = -1;
a = [1 -1];
[Hf,w] = freqz(b,a,[0:pi/1024:pi]);
if flag
    figure;subplot 211;plot(w*fs/2/pi,20*log(abs(Hf))); % 幅频响应
    subplot 212;plot(w*fs/2/pi,angle(Hf));              % 相频响应
end
output_data = filter(b,a,input_data);
end