% Designed By yandong, ZHANG
% email: zhangyandong1987@gmail.com
% Peking University
%16QAM的调制
function [signal_sendI,signal_sendQ,message,signal_base_band]=Modulation(MES_LEN,SYM_LEN,INSERT_TIMES,PETAL,BETA)
%信源产生
message=randn(1,MES_LEN);
message(message<=0)=0;
message(message>0)=1;
%基带调制
signal_base_band1I=message(1:4:end-3);
signal_base_band3I=message(3:4:end-1);
signal_base_band2Q=message(2:4:end-2);
signal_base_band4Q=message(4:4:end);
signal_base_bandI=zeros(1,SYM_LEN);
signal_base_bandQ=zeros(1,SYM_LEN);
for i=1:1:SYM_LEN
    tempI=[signal_base_band1I(i),signal_base_band3I(i)];
    if     tempI==[1,0]
            signal_base_bandI(i)=-3;
    elseif tempI==[1,1]
            signal_base_bandI(i)=-1;
    elseif tempI==[0,1]
            signal_base_bandI(i)=1;
    else
            signal_base_bandI(i)=3;
    end;
    tempQ=[signal_base_band2Q(i),signal_base_band4Q(i)];
    if     tempQ==[1,0]
            signal_base_bandQ(i)=-3;
    elseif tempQ==[1,1]
            signal_base_bandQ(i)=-1;
    elseif tempQ==[0,1]
            signal_base_bandQ(i)=1;
    else
            signal_base_bandQ(i)=3;
    end;
end;
%星座图
signal_base_band=signal_base_bandI+signal_base_bandQ*j;
scatterplot(signal_base_band);
axis([-5,5,-5,5]);
grid on;
title('发射机16QAM信号的眼图');
%插值
signal_after_insertI=zeros(1,SYM_LEN*INSERT_TIMES);
signal_after_insertI(1:INSERT_TIMES:end)=signal_base_bandI;
signal_after_insertQ=zeros(1,SYM_LEN*INSERT_TIMES);
signal_after_insertQ(1:INSERT_TIMES:end)=signal_base_bandQ;
figure;
subplot(2,1,1)
stem([1:20*INSERT_TIMES],signal_after_insertI(1:20*INSERT_TIMES),'.b');
title('发射机插值后信号的同相分量');
grid on;
subplot(2,1,2)
stem([1:20*INSERT_TIMES],signal_after_insertQ(1:20*INSERT_TIMES),'.b');
title('发射机插值后信号的正交分量');
grid on;
%滤波
signal_after_fiterI = rcosflt(signal_after_insertI,1,INSERT_TIMES,'fir/fs/sqrt',BETA,PETAL+1)';
signal_after_fiterQ = rcosflt(signal_after_insertQ,1,INSERT_TIMES,'fir/fs/sqrt',BETA,PETAL+1)';
signal_sendI = signal_after_fiterI(INSERT_TIMES*(PETAL+1)+1:end-INSERT_TIMES*(PETAL+1));
signal_sendQ = signal_after_fiterQ(INSERT_TIMES*(PETAL+1)+1:end-INSERT_TIMES*(PETAL+1));
figure;
subplot(2,1,1)
stem([1:20*INSERT_TIMES],signal_sendI(1:20*INSERT_TIMES),'.b');
title('发射机成型滤波基带信号的同相分量');
grid on;
subplot(2,1,2)
stem([1:20*INSERT_TIMES],signal_sendQ(1:20*INSERT_TIMES),'.b');
title('发射机成型滤波基带信号的正交分量');
grid on;