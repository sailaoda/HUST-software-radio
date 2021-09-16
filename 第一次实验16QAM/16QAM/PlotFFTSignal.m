function PlotFFTSignal(x,sampling_freq)

% 画出FFT变换后的图像
% 数据的长度
data_len = length(x);
% FFT变换获得频域
fft_x = abs(fft(x));
% 频域信号正半轴
fre_x = fft_x(1:data_len/2);

% 频率范围的最大值（根据奈奎斯特采样定理，采样率是最大频率的2倍）
max_fre = sampling_freq/2;

% 频域范围
plotscope = linspace(0,max_fre,data_len/2);

% 画图
plot(plotscope,fre_x,'Linewidth',1.5);