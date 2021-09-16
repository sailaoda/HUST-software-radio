function PlotTDSignal(x,sampling_freq,symbol_rate)

% 画出信号的时域图像
% 数据长度
data_len = length(x);
% 时域间隔
time_interval = 1/sampling_freq;
% 时域范围
plotscope = 0:time_interval:(data_len-1)*time_interval;

% 画图
plot(plotscope,x,'Linewidth',1.5);

% 比特间隔
bit_interval = 1/symbol_rate;
% 比特数量
bit_num = floor(data_len/sampling_freq*symbol_rate);

for k = 1:bit_num
    hold on
    plot([k*bit_interval k*bit_interval],[min(x) max(x)],'--k','Linewidth',1.5);
end