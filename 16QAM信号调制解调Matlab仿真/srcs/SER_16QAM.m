% Designed By yandong, ZHANG
% email: zhangyandong1987@gmail.com
% Peking University
function SER_THER=SER_16QAM(SNR)
M=16;
X=sqrt(3/(M-1)*10.^((SNR)/10));
P_sqrM=2*(1-1/sqrt(M))*1/2*erfc(X/sqrt(2));
PM=1-(1-P_sqrM).^2;
SER_THER=PM;