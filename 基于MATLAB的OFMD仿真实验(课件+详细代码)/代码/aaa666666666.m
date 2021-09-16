clc;
fs = 20e6;
gi = 1/4;                
fftlen = 64;
gilen = gi*fftlen;          


ShortTrain = sqrt(13/6) * [0 0 1+j 0 0 0 -1-j 0 0 0 1+j 0 0 0 -1-j ...
                       0 0 0 -1-j 0 0 0 1+j 0 0 0 0 0 0 -1-j 0 0 0 ...
                       -1-j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0].';

short_demap = zeros(64, 1);
short_demap([7:32 34:59],:) = ShortTrain;
short_demap([33:64 1:32],:) = short_demap;  
% 将频域的短训练序列转化到时域
ShortTrain=sqrt(64)*ifft(sqrt(64/52)*short_demap);  
ShortTrain =ShortTrain(1:16);
transmit=[ShortTrain;ShortTrain;ShortTrain;ShortTrain;ShortTrain;
          ShortTrain;ShortTrain;ShortTrain;ShortTrain;ShortTrain];

phase=zeros(1,1);
mse=zeros(1,1);
error = zeros(1,500);
snr = 0:1:20;
for snr_idx = 1:length(snr)
    for n = 1:500  
        len = length(transmit);   % 计算传输信号长度
        noise =sqrt(1/(10^(snr(snr_idx)/10))/2)*( randn(len,1)+j*randn(len,1));
        % 加噪声
        transmit1 = transmit + noise; 
        % 加频偏 [0:total_length-1]/fs=nTs    ▲f=0.2*fs/fftlen
        cfo = 0.2*fs/fftlen/fs*[0:len-1];
        phase_shift = exp(j*2*pi*cfo).';
        transmit2 = transmit1.*phase_shift;   % 将频偏加到传输的信号上

        LTE = 16;  %长度为16的窗口
        phase=0;
        
        for i=1:(len-LTE)     
            %每一个数据与d个数据后的数据共轭相乘，求总和
            phase=phase+transmit2(i).*conj(transmit2(i+LTE));
        end 
        
        %求估计出的频偏
        cfo_est = -angle(phase) / (2*LTE*pi/fs);  
        %求频偏估计误差
        error(n) = (cfo_est - (0.2*fs/fftlen))/(0.2*fs/fftlen); 
    end
 
mse(snr_idx) = mean(abs(error).^2);
end

semilogy(snr,mse,'-o');
xlabel('SNR/dB');
ylabel('MSE');
grid on;