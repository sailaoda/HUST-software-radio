function output_data = hb_filter(fs, fpass, fstop, rs, rp, input_data, flag)
%%% HB抽取滤波器
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
% dev = [(10^(rp/20)-1)/(10^(rp/20)+1) 10^(-rs/20)];
dev = [10^(-rp/20) 10^(-rs/20)];
% dev = [rp rs];
[n,Wn,a,w] = firpmord([fpass fstop],[1 0],dev,fs); % n:阶数;Wn:归一化带宽
b = firpm(max(3,n),Wn,a,w);                               % b:分子系数
if flag
    figure;
    freqz(b,1,1024,fs);
end
output_data = filter(b,1,input_data);
end