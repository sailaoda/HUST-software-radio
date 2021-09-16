clear
load('signal_in.mat')
fs=2.5e9;%采样率
fc=50e6;%载波频率
n=length(signal_in);%16QAM数据长度
figure(1)
plot((-n/2:n/2-1)*(fs/n),10*log10(abs(fftshift(fft(signal_in)))))%传输前16QAM的功率谱
title('发端信号功率谱')

x=repmat(sync,1,100); %同步头采样100倍
x=reshape(x',[],1);
head=x;%获得同步头序列

%在信道中传输
out=channel(signal_in,15272);
m=zeros(1,length(out)/2);
out_1=out./abs(out);

%提取同步头信息
for i=1:length(m)%相关运算
    m(i)=sum(head'.*out_1(i:i+5000-1));
end
figure(2)
plot(abs(m));%画出同步头准确位置
title('同步头准确位置')
 [~,start1]=find(m==max(m));
 [~,start2]=find(m==min(m));
 start=round((start1+start2)/2)-1;%提取出信号开始位置

msg=out(start+5000:start+65000-1)';%传输后去掉同步头的16QAM信号
figure(3)
subplot(1,2,1)
plot(signal_in(537+5000:end),'r')%画出传输前的16QAM信号
hold on
plot(msg,'b')%画出传输后的16QAM信号
title('输入输出对照')
subplot(1,2,2)
plot(signal_in(537+5000:end),'r')%画出传输前的16QAM信号
hold on
plot(msg,'b')%画出传输后的16QAM信号
axis([1000 2000 -4 4])
title('输入输出对照（局部）')

A=10*log10(abs(fftshift(fft(msg))));%求传输后的16QAM信号功率谱振幅
n_msg=length(msg);%变换后的信号长度
fs_msg=fs;
fshift_msg=(-n_msg/2:n_msg/2-1)*(fs_msg/n_msg);
figure(4)
plot(fshift_msg,A)%画出传输后的16QAM功率谱函数
title('收端信号功率谱')

t=1/fs_msg:1/fs_msg:n_msg/fs_msg;
I_signal=2*msg.*cos(2*pi*fc.*t');%解调出同相信号
Q_signal=-2*msg.*sin(2*pi*fc.*t');%解调出正交信号

ff=[ones(n_msg*1/100,1);zeros(n_msg*98/100,1);ones(n_msg*1/100,1)];%滤波器，保留主瓣
I_P=fft(I_signal).*ff;%滤波
Q_P=fft(Q_signal).*ff;%滤波

I_signal_fin=ifft(I_P);%滤波后的I路信号
Q_signal_fin=ifft(Q_P);%滤波后的Q路信号
QAM_signal_fin=I_signal_fin+1i*Q_signal_fin;%二路信号叠加

QAM_signal_down=(1:600)';%下采样
for x=1:600%下采样取600个16QAM信号
    QAM_signal_down(x)=QAM_signal_fin(x*100-50);
end
scatterplot(QAM_signal_down);%画采样后的16QAM星座图

%找出偏移角度
point=0;
num=0;
for x=1:600
    if((real(QAM_signal_down(x))>=1.5)&&(imag(QAM_signal_down(x))>=1.5))%划定对应3+3i点的大致位置
        point=point+QAM_signal_down(x);
        num=num+1;
    end
end
point_aver=point/num;%对应3+3i点的平均位置
QAM_fin=QAM_signal_down*(3+3i)/point_aver;%纠正偏移

scatterplot(QAM_fin);%画经过校正的16QAM星座图