clear all; clc;
gi = 1/4;                
fftlen = 64;
gilen = gi*fftlen;          

ShortTrain = sqrt(13/6) * [0 0 1+j 0 0 0 -1-j 0 0 0 1+j 0 0 0 -1-j ...
                       0 0 0 -1-j 0 0 0 1+j 0 0 0 0 0 0 -1-j 0 0 0 ...
                       -1-j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0].';

short_demap = zeros(64, 1);
short_demap([7:32 34:59],:) = ShortTrain;
short_demap([33:64 1:32],:) = short_demap;
% 将频域的短训练序列转化到时域并进行功率归一化
ShortTrain=sqrt(64)*ifft(sqrt(64/52)*short_demap); 
ShortTrain =ShortTrain(1:16);
short_train_blks=[ShortTrain;ShortTrain;ShortTrain;ShortTrain;ShortTrain;
                  ShortTrain;ShortTrain;ShortTrain;ShortTrain;ShortTrain];

longTrain = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 ...
     1 1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1].';
 
long_demap = zeros(64, 1);
long_demap([7:32 34:59],:) = longTrain;
long_demap([33:64 1:32],:) = long_demap;

% 将频域的长训练序列转化到时域并进行功率归一化
longTrain=sqrt(64)*ifft(sqrt(64/52)*long_demap);
% 取长训练序列的后32位作为cp前缀
long_train_syms = [longTrain(33:64,:); longTrain; longTrain];
% 构成发送序列
transmit = [short_train_blks; long_train_syms]; 

len = length(transmit);
error = zeros(500,1);
time_est = zeros(500,1);
snr = 0:1:10;
for snr_idx = 1:length(snr)
    for n = 1:500
        noise = sqrt(1/(10^(snr(snr_idx)/10))/2)* ...
                    (randn(len,1)+j*randn(len,1));
        transmit1 = transmit + noise;   % 加噪声
        i_matrix=zeros(64,1);
        j_matrix=zeros(51,1);
        for j=150:200        % 正确的同步位置在160+32+1处，选择范围包括193
            for i=1:64       % 长训练序列的64位
                % 接受序列与长训练序列共轭相乘
                i_matrix(i)=transmit1(j-1+i).*conj(longTrain(i)); 
                % 以每一个bit为起始计算出一个和
                j_matrix(j-149)=j_matrix(j-149)+i_matrix(i);
            end
        end
        [a,b] = max(abs(j_matrix));   % 求和最大的，相关程度最高

        time_est(n) = 149 + b;    % 求计算出的同步位置
        error(n) = time_est(n) - 193;    % 估计位置偏差
         

    end
end


mse(snr_idx)= mean(abs(error).^2); % 求mse
semilogy(snr,mse);
xlabel('SNR/dB');
ylabel('MSE');
grid on;
