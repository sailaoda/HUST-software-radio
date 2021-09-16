% OFDM子载波频谱
clear all; 
close all; 
clc;  
Num_Sc = 4; % 5个子载波，零点有一个
Ts = 1; % 1s 
F_space = 1/Ts;  
F = -F_space*Num_Sc/2-4:0.001:F_space*Num_Sc/2+4; %采样点取值范围：-6到6
F_spectrum = zeros(Num_Sc,length(F));%初始化矩阵
for i = -Num_Sc/2:1:Num_Sc/2 %采样绘图
F_spectrum(i+Num_Sc/2+1,1:end)= sin(2*pi*(F-i*F_space).*Ts/2)./(2*pi*(F-i*F_space).*Ts/2); 
end  
plot(F,F_spectrum) 
grid on