% Designed By yandong, ZHANG
% email: zhangyandong1987@gmail.com
% Peking University
function [mymessage,mysignal_base_band]=Receiver(signal_receiveI,signal_receiveQ,INSERT_TIMES,MES_LEN,SYM_LEN,BETA,PETAL);
%-------------------------接收机----------------------------------
%匹配滤波
signal_after_filterI = rcosflt(signal_receiveI,1,INSERT_TIMES,'fir/fs/sqrt',BETA,PETAL+1)';
signal_after_filterQ = rcosflt(signal_receiveQ,1,INSERT_TIMES,'fir/fs/sqrt',BETA,PETAL+1)';
signal_after_filterI = signal_after_filterI(INSERT_TIMES*(PETAL+1)+1:end-INSERT_TIMES*(PETAL+1));
signal_after_filterQ = signal_after_filterQ(INSERT_TIMES*(PETAL+1)+1:end-INSERT_TIMES*(PETAL+1));
figure;
subplot(2,1,1)
stem([1:20*INSERT_TIMES],signal_after_filterI(1:20*INSERT_TIMES),'.r');
title('接收机匹配滤波后的同相分量');
grid on;
subplot(2,1,2);
stem([1:20*INSERT_TIMES],signal_after_filterQ(1:20*INSERT_TIMES),'.r');
title('接收机匹配滤波后的正交分量');
grid on;
%下采样
signal_after_downsampleI = signal_after_filterI(1:INSERT_TIMES:end); 
signal_after_downsampleQ = signal_after_filterQ(1:INSERT_TIMES:end);
figure;
subplot(2,1,1)
stem([1:20*INSERT_TIMES],signal_after_downsampleI(1:20*INSERT_TIMES),'.r');
title('接收机下采样后的同相分量');
grid on;
subplot(2,1,2)
stem([1:20*INSERT_TIMES],signal_after_downsampleQ(1:20*INSERT_TIMES),'.r');
title('接收机下采样后的正交分量');
grid on;
% 星座图
figure;
plot(signal_after_downsampleI, signal_after_downsampleQ,'r+');
axis([-2 2 -2 2]);
xlabel('I路');
ylabel('Q路');
title('接收机解调信号星座图');
axis([-5,5,-5,5]);
grid on;
%符号判决
mysignal_base_bandI=zeros(1,SYM_LEN);
mysignal_base_bandQ=zeros(1,SYM_LEN);
for i=1:1:SYM_LEN
    if signal_after_downsampleI(i)>=2
        mysignal_base_bandI(i)=3;
    elseif signal_after_downsampleI(i)>=0
        mysignal_base_bandI(i)=1;
    elseif signal_after_downsampleI(i)>=-2
        mysignal_base_bandI(i)=-1;
    else
        mysignal_base_bandI(i)=-3;
    end;
    if signal_after_downsampleQ(i)>=2
        mysignal_base_bandQ(i)=3;
    elseif signal_after_downsampleQ(i)>=0
        mysignal_base_bandQ(i)=1;
    elseif signal_after_downsampleQ(i)>=-2
        mysignal_base_bandQ(i)=-1;
    else
        mysignal_base_bandQ(i)=-3;
    end;
end;
mysignal_base_band=zeros(1,SYM_LEN);
mysignal_base_band=mysignal_base_bandI+mysignal_base_bandQ*j;
%符号到比特变换
mymessage=zeros(1,MES_LEN);
for i=1:1:SYM_LEN
    tempS=[mysignal_base_bandI(i),mysignal_base_bandQ(i)];
    tempB=zeros(1,4);
    if      tempS==          [-3,-3]
            tempB=[1,1,0,0];
    elseif tempS==          [-3,-1]
            tempB=[1,1,0,1];
    elseif tempS==          [-3, 1]
            tempB=[1,0,0,1];
    elseif tempS==          [-3, 3]
            tempB=[1,0,0,0];
    elseif tempS==          [-1,-3]
            tempB=[1,1,1,0];
    elseif tempS==          [-1,-1]
            tempB=[1,1,1,1];
    elseif tempS==          [-1, 1]
            tempB=[1,0,1,1];
    elseif tempS==          [-1, 3]
            tempB=[1,0,1,0];
    elseif tempS==          [ 1,-3]
            tempB=[0,1,1,0];
    elseif tempS==          [ 1,-1]
            tempB=[0,1,1,1];
    elseif tempS==          [ 1, 1]
            tempB=[0,0,1,1];
    elseif tempS==          [ 1, 3]
            tempB=[0,0,1,0];
    elseif tempS==          [ 3,-3]
            tempB=[0,1,0,0];
    elseif tempS==          [ 3,-1]
            tempB=[0,1,0,1];
    elseif tempS==          [ 3, 1]
            tempB=[0,0,0,1];
    elseif tempS==          [ 3, 3]
            tempB=[0,0,0,0];
    else
            null;
    end;
    mymessage((i-1)*4+1:i*4)=tempB;
end;
