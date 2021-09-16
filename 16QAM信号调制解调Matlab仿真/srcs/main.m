% Designed By yandong, ZHANG
% email: zhangyandong1987@gmail.com
% Peking University

clear all;
close all;
clc;
%参量定义
MES_LEN=4*10000; % source message length
SYM_LEN=MES_LEN/4;% symbol length
INSERT_TIMES=8; %insert times befor filter
PETAL=5; %num of petals each side of filter
BETA=0.5; %filter bandwidth
SELECT=2; %mode slect

switch SELECT
    case 1,%模式1:单个SNR下的调制、解调、误码分析
            SNR=12;%符号SNR值
            %产生调制信号
            [signal_sendI,signal_sendQ,message,signal_base_band]=Modulation(MES_LEN,SYM_LEN,INSERT_TIMES,PETAL,BETA);
            figure;
            %加高斯白噪声
            [signal_receiveI,signal_receiveQ]=AddNoise(signal_sendI,signal_sendQ,SNR,INSERT_TIMES);
            figure;
            %接收机解调
            [mymessage,mysignal_base_band]=Receiver(signal_receiveI,signal_receiveQ,INSERT_TIMES,MES_LEN,SYM_LEN,BETA,PETAL);
            figure;
            %误码率统计
            ErrBit = MES_LEN-sum((mymessage == message));
            ErrSym = SYM_LEN-sum((mysignal_base_band == signal_base_band));
            MyErrBitRate=ErrBit/MES_LEN;
            MyErrSymRate=ErrSym/SYM_LEN;
            %理论误符号率公式
            TherSer=SER_16QAM(SNR);
    case 2,%模式2：误码曲线的绘制
            SNR = [10 12 14 16 18 20]; %符号SNR值
            SumBit = zeros(1,length(SNR));
            SumErrBit = zeros(1,length(SNR));            
            SumSym = zeros(1,length(SNR));
            SumErrSym = zeros(1,length(SNR));
            h=waitbar(0,'正在绘制，请稍候 …… ');
            for k = 1:length(SNR)
                SumSym(1,k) = 0;
                SumErrSym(1,k) = 0;
                SumBit(1,k) =0;
                SumErrBit(1,k) =0;
                while(SumErrSym(1,k)<100 && SumSym(1,k)<SYM_LEN*50) %出现100个误符号 或者 仿真点数太多时停止
                    %产生调制信号
                    [signal_sendI,signal_sendQ,message,signal_base_band]=Modulation(MES_LEN,SYM_LEN,INSERT_TIMES,PETAL,BETA);
                    
                    close all;
                    %加高斯白噪声
                    [signal_receiveI,signal_receiveQ]=AddNoise(signal_sendI,signal_sendQ,SNR(k),INSERT_TIMES);
                    
                    close all;
                    %接收机解调
                    [mymessage,mysignal_base_band]=Receiver(signal_receiveI,signal_receiveQ,INSERT_TIMES,MES_LEN,SYM_LEN,BETA,PETAL);
                    
                    close all;
                    %误码率统计
                    ErrBit = MES_LEN-sum((mymessage == message));
                    ErrSym = SYM_LEN-sum((mysignal_base_band == signal_base_band));
                    SumErrBit(1,k) = SumErrBit(1,k) + ErrBit;
                    SumErrSym(1,k) = SumErrSym(1,k) + ErrSym;
                    SumBit(1,k) = SumBit(1,k) +MES_LEN;
                    SumSym(1,k) = SumSym(1,k) +SYM_LEN;
                end
                waitbar(k/length(SNR),h);
            end
            close(h);
            MyErrBitRate = SumErrBit./SumBit      %仿真得到的误比特率
            MyErrSymRate = SumErrSym./SumSym      %仿真得到的误符号率
            TherSer=SER_16QAM(SNR);    %理论误符号率      
            %绘制误符号率和误比特率曲线
            figure;
            semilogy(SNR, MyErrSymRate, 'b-*');
            hold on;
            semilogy(SNR, MyErrBitRate, 'r-.');
            hold on;
            semilogy(SNR, TherSer, 'r-*');
            
            legend('仿真误符号率','仿真误比特率','理论误符号率');
            xlabel('符号信噪比 /dB');
            ylabel('错误概率');
            grid on;
end