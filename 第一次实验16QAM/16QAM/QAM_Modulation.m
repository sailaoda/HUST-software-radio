function modulated_signal = QAM_Modulation(input,sys_param)
%正交调幅法
n=length(input);
m=sys_param.sample_freq/sys_param.symbol_rate;% 一个比特的点数
dt=1/sys_param.sample_freq; %采样时间间隔
T=n/sys_param.symbol_rate;
t=0:dt:T-dt;
%I路
I=input(1:2:n-1);
%2-4电平转换
X=two2four(I,4*m);

%Q路
Q=input(2:2:n);
Y=two2four(Q,4*m);
% 基带成形滤波
rcos=firrcos(16,sys_param.symbol_rate/4,sys_param.symbol_rate/4,sys_param.sample_freq);
I=filter(rcos,1,X);
Q=filter(rcos,1,Y);

modulated_signal=I.*cos(2*pi*sys_param.carrier_freq*t)-Q.*sin(2*pi*sys_param.carrier_freq*t);


