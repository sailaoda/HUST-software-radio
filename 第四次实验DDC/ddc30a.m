%数字下变频仿真程序
%数字下变频的主要作用有两点：

%一、对A/D采样后的高频/中频信号序列进行频谱搬移（通过与数控振荡器产生的数字本振信号序列进行相乘下变频到基频）。
%二、对基频上高采样率的信号序列进行抽取，多采样率变换，降低数字信号序列密度。
                          
%%%%%实际的数字下变频在对高频/中频信号序列进行A/D采样之前为了防止发生频率混叠，要进行预滤波处理。
%%%%在对基频上高采样率的信号序列进行抽取之前，要通过CIC滤波，HB滤波，FIR滤波，以防止抽取时发生频谱混叠。
                         
                        
clear all;
close all;
fsamp=96e6;        %fsamp=96MHz 输入采样频率为96MHz
Ts=1/fsamp;        %Ts为fsamp的倒数 即输入采样间隔Ts
band=30e6;         %预设的采样带宽为30MHz
Tp=60e-6;          %预设的采样时间周期Tp为60us
N=Tp*fsamp;        %N为输入采样频率与采样时间周期之积。表示在采样时间周期Tp内，以fsamp的采样率采样可以得到的采样点数   N = 5760
u=band/Tp;         %u为带宽除以时宽。表示在单位时间间隔内的频带宽度。也即这30M的带宽分布在Tp=60us的时间周期上，单位时间的频带宽度
t=-Tp/2:Tp/N:Tp/2-Tp/N;       %t取点从-Tp/2开始以Tp/N为步进值增加到Tp/2-Tp/N。

f0=70e6;           %输入的已调频信号载波频率为70MHz
xs=cos(2*pi*(f0*t+0.5*u*t.^2));        %输入的已调频信号经fsamp=96MHz带通采样后的输出。相当于A/D转换后的数字信号序列
S0=fft(xs,N);      %S0是对A/D转换后的数字信号序列进行N点fft的结果；
S1=abs(S0);        %S1是对s0求模的结果；
S2=(S1);
S2=awgn(S2,10);    %在S2的频谱中加入10db的高斯白噪声
f=0:fsamp/N:fsamp-fsamp/N;       %f的取点由0开始以fsamp/N为步进值直到fsamp-fsamp/N结束
figure(1);         %画出载频为70MHz有用信号带宽为30MHz的带通信号序列频谱
plot(f/1e6,20*log10(S2/max(S2)));           %横轴以MHz为单位，纵轴以dB形式，其中S2/max(S2)表示输出该带通信号序列相对幅度大小，对它取对数后的结果就是dB的形式了。
title('载频为70MHz有用信号带宽为30MHz的带通信号序列频谱');
xlabel('frequency(MHz)');                   %从频谱图中可以看出信号序列频谱有（11MHz，41MHz）和（55MHz，85MHz）两部分。
ylabel('Magnitude(dB)');                    %这是因为经fsamp=94MHz带通采样时，在fsamp/2=48MHz处发生了频谱折叠，原来信号序列频谱（55M，85M）折叠到（11MHz，41MHz）了。
grid on                                     %这两部分频谱形状一致，没有发生频谱混叠。这里的带通采样速率fsamp=96MHz是通过计算得出来的。
                                            %具体计算式如下：fsamp>=4f0/(2n+1) 且fsamp>=2B。这里f0指信号序列中心频率，B指信号序列带宽 n取正整数。
 
%NCO数控振荡器模块%
for t=1:N
    t1=(t-1)*Ts;
    ncoi_c(t)=cos(2*pi*f0*t1);             %产生频率为f0的cos数控本振（I路），这里产生数控本振的时间间隔与A/D采样间隔相同，便于序列后续相乘。
end
 
for t=1:N
    t1=(t-1)*Ts;
    ncoq_c(t)=sin(2*pi*f0*t1);            %产生频率为f0的sin数控本振（Q路），这里产生数控本振的时间间隔与A/D采样间隔相同，便于序列后续相乘。
end
ncoi=awgn(ncoi_c,80);         %对产生的I路本振序列加入80dB的高斯白噪声
ncoq=awgn(ncoq_c,80);         %对产生的Q路本振序列加入80dB的高斯白噪声
 
f=0:fsamp/N:fsamp-fsamp/N;    %f取点从0开始以fsamp/N为步进值直到fsamp-fsamp/N结束
u1=abs(fft(ncoi));            %对加入高斯白噪声的I路本振信号序列进行FFT后取模
u2=abs(fft(ncoq));            %对加入高斯白噪声的Q路本振信号序列进行FFT后取模
figure(2);                    %画出加入高斯白噪声后的数控振荡器I路信号频谱
plot(f/1e6,20*log10(u1/max(u1)));%横轴以MHz为单位，纵轴是dB形式
title('加入高斯白噪声的数控振荡器I路信号频谱');
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');
grid on
figure(3);                     %画出加入高斯白噪声后的数控振荡器Q路信号频谱
plot(f/1e6,20*log10(u2/max(u2)));%横轴以MHz为单位，纵轴是dB形式
title('加入高斯白噪声的数控振荡器Q路信号频谱');
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');
grid on
 
for n=1:1:N
    ysi(n)=xs(n)*ncoi(n);%A/D带通采样后信号序列与数字本振I路信号序列混频相乘（下变频）
    ysq(n)=xs(n)*ncoq(n);%A/D带通采样后信号序列与数字本振Q路信号序列混频相乘（下变频）
end
 
u1=abs(fft(ysi));%对I路下变频后序列进行FFT，取模后结果送到u1
u2=abs(fft(ysq));%对Q路下变频后序列进行FFT，取模后结果送到u2
f=0:fsamp/N:fsamp-fsamp/N;%f取点从0开始，以fsamp/N为步进值直到fsamp-fsamp/N结束
figure(4);%画出输出下变频后的I路信号频谱
plot(f/1e6,20*log10(u1/max(u1)));
title('信号序列I路下变频后输出');
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');
grid on
figure(5);%画出输出下变频后的Q路信号频谱
plot(f/1e6,20*log10(u2/max(u2)));
title('信号序列Q路下变频后输出');
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');
grid on

u=abs(fft(ysi-j*ysq));%u=u1+u2，对下变频后的信号序列进行FFT,取模后送到u
figure(6);%画出下变频后的I+JQ信号频谱
plot(f/1e6,20*log10(u/max(u)));
title('信号序列下变频后输出（I+JQ)');
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');
grid on
 
%运用Remez算法设计低通FIR滤波器
%所设计的低通FIR滤波器满足以下参数：采样率：fs=96MHz；通带截止频率：15MHz；阻带起始频率：22.5MHz；最小衰减：80dB；通带波纹：0.01dB；  
fs=fsamp;
band=30e6;                                                 %滤波器带宽
gdd=7.5e6;                                                 %滤波器过渡带宽 
wp=(band/2)*2*pi/fs;                                       %通带截止频率归一化
ws=(band/2+gdd)*2*pi/fs;                                   %阻带起始频率归一化
tr_width=gdd*2*pi/fs;                                      %过渡带宽归一化
rp=0.01;                                                   %通带波纹小于0.01dB
rs=80;                                                     %最小阻带衰减80dB
f=[band/2 band/2+gdd];                                     %低通滤波器的f向量:f=[通带截止频率 阻带起始频率]
a=[1 0];                                                   %低通滤波器分母为1。
dev=[(10^(rp/20)-1)/(10^(rp/20)+1) 10^(-rs/20)];           %δ1通带最大波纹系数，δ2阻带最大波纹系数
[NN,fo,ao,w]=remezord(f,a,dev,fs);                         %运用remezord函数计算FIR滤波器长度NN，NN=54。
fira=remez(NN,fo,ao,w);                                    %运用remez函数进行FIR低通滤波器设计
figure(7);                                                 %抗混叠FIR滤波器频谱图
freqz(fira,1,1024,fs);                                     %数字滤波器fira的频率响应
title('抗混叠FIR滤波器频谱图');
                                                           %freqz(b,a,...) plots the magnitude and unwrapped phase of the frequency response of the filter.
[hf,f1]=freqz(fira,1,NN,fs);
                                                           % [h,f]=freqz(b,a,l,fs) returns the frequency response vector h and the corresponding frequency
                                                           %vector f for the digital filter whose transfer function
                                                           %is determined by the (real or complex) numerator and denominator polynomials represented in the vectors b and a,
                                                           %respectively. The vectors h and f are both of length l. For this syntax, the frequency response
                                                           %is calculated using the sampling frequency specified by the scalar fs (inhertz). The frequency vector f is calculated 
                                                           %in units of hertz (Hz). The frequency vector f has values ranging from 0 to fs/2Hz.
figure(8);      %FIR1低通滤波器的频谱图
f=f1;
adg=1*20*log10(abs(hf));
plot(f/1e6,adg);
grid on
title('FIR1 Magnitude Response(dB)');
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');
 
ysi1=conv(fira,ysi);                     %下变频后I路信号通过抗混叠FIR滤波器   时域相乘等效于频域卷积
ysq1=conv(fira,ysq);                     %下变频后Q路信号通过抗混叠FIR滤波器   时域相乘等效于频域卷积
 
Nu=length(ysi1);
f=0:fs/Nu:fs-fs/Nu;                     %f取值由0开始，以步进值为fs/Nu，直到fs-fs/Nu结束。
figure(9);                              %画出经抗混叠FIR滤波器滤波后的I路信号输出
adg=abs(fft(ysi1));
plot(f/1e6,20*log10(adg/max(adg)));
grid on
title('经抗混叠FIR滤波器滤波后的I路信号输出');
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');
Nu=length(ysq1);
f=0:fs/Nu:fs-fs/Nu;
figure(10);                             %画出经抗混叠FIR滤波器滤波后的Q路信号输出
adg=abs(fft(ysq1));
plot(f/1e6,20*log10(adg/max(adg)));
grid on
title('经抗混叠FIR滤波器滤波后的Q路信号输出');
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');
 
figure(11);
ysi_IQ1=ysi1-j*ysq1;               %ysi_IQ1=ysi1-j*ysq1???????????????
adg=abs(fft(ysi_IQ1));             %对经过抗混叠FIR滤波器滤波后的信号进行合并，并对合并后的信号进行FFT，结果送adg。
plot(f/1e6,20*log10(adg/max(adg)));
grid on
title('抗混叠FIR滤波器输出信号频谱(I+JQ)');
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');
 
ysi11(1:ceil(Nu/2))=ysi1(1:2:Nu);                         %对FIR I路输出信号进行2倍抽取  ceil函数是向高取整  在ysil中的前Nu个数中隔一个取一个
ysq11(1:ceil(Nu/2))=ysq1(1:2:Nu);                         %对FIR Q路输出信号进行2倍抽取  ceil函数是向高取整
 
figure(12);
Nu=length(ysi11);
adg=abs(fft(ysi11));
f=0:fs/(2*Nu):fs/2-fs/(2*Nu);
plot(f/1e6,20*log10(adg/max(adg)));
grid on
title('dec2 Magnitude Response(dB) (I)');       %输出经下变频后，通过抗混叠FIR滤波器滤波，并完成2倍抽取的数字下变频I路信号频谱图
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');
 
figure(13);
Nu=length(ysq11);
adg=abs(fft(ysq11));
f=0:fs/(2*Nu):fs/2-fs/(2*Nu);
plot(f/1e6,20*log10(adg/max(adg)));
grid on
title('dec2 Magnitude Response(dB) (Q)');      %输出经下变频后，通过抗混叠FIR滤波器滤波，并完成2倍抽取的数字下变频Q路信号频谱图
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');

ysout=ysi11-j*ysq11;                          %对经下变频后，通过抗混叠FIR滤波器滤波，并完成2倍抽取的数字下变频I/Q两路信号序列进行合并，结果送ysout。
 
figure(14);                                   %原A/D采样信号序列经下变频并2倍抽样后的频谱(I+jQ)
Nu=length(ysout);
adg=abs(fft(ysout));
f=0:fs/(2*Nu):fs/2-fs/(2*Nu);
plot(f/1e6,20*log10(adg/max(adg)));
grid on
title('原A/D采样信号序列经下变频并2倍抽样后的频谱(I+jQ)');
xlabel('frequency(MHz)');
ylabel('Magnitude(dB)');

