function output_data = fir_filter(fs, fpass, fstop, rs, rp, input_data, flag)
%%% FIR滤波器
%%% 输入
%       fs：采样频率
%       fpass：通带截止频率
%       fstop：阻带截止频率
%       rs：阻带波纹
%       rp：通带波纹
%       input_data：输入序列
%       flag：画图标志位
%%% 输出
%       output_data：滤波后的序列
dev = [rp rs];
[n,Wn,beta,ftype] = kaiserord([fpass fstop],[1 0],dev,fs); % n:阶数;Wn:归一化带宽
b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');             % b:分子系数
if flag
    figure;
    freqz(b,1,1024,fs);
end
output_data = filter(b,1,input_data);
end