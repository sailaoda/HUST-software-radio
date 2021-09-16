% Designed By yandong, ZHANG
% email: zhangyandong1987@gmail.com
% Peking University
function [signal_receiveI,signal_receiveQ]=AddNoise(signal_sendI,signal_sendQ,SNR,INSERT_TIMES);
signal_receiveI = awgn(signal_sendI,SNR-10*log10(INSERT_TIMES),'measured');
signal_receiveQ = awgn(signal_sendQ,SNR-10*log10(INSERT_TIMES),'measured');
figure;
subplot(2,1,1)
stem([1:20*INSERT_TIMES],signal_sendI(1:20*INSERT_TIMES),'.b');
hold on;
stem([1:20*INSERT_TIMES],signal_receiveI(1:20*INSERT_TIMES),'.r');
title('加入噪声前后的同相分量');
grid on;
subplot(2,1,2)
stem([1:20*INSERT_TIMES],signal_sendQ(1:20*INSERT_TIMES),'.b');
hold on
stem([1:20*INSERT_TIMES],signal_receiveQ(1:20*INSERT_TIMES),'.r');
title('加入噪声前后的正交分量');
grid on;