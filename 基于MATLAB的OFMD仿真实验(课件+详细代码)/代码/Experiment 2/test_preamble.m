gi = 1/4;                   % Guard interval: in the Brazil_E model,the maxmum delay is 2e-6s, equals to 16 points. 
fftlen = 64;
gilen = gi*fftlen;           % Length of guard interval (points)
blocklen = fftlen + gilen;   % total length of the block with CP

ShortTrain = sqrt(13/6)*[0 0 1+j 0 0 0 -1-j 0 0 0 1+j 0 0 0 -1-j 0 0 0 -1-j 0 ...
 0 0 1+j 0 0 0 0 0 0 -1-j 0 0 0 -1-j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0].';
NumShortTrainBlks = 10;

LongTrain = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 ...
      1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1].';
NumLongTrainBlks = 2;

% Preamble generation
short_train = tx_freqd_to_timed(ShortTrain);
%plot(abs(short_train));
short_train_blk = short_train(1:16);
short_train_blks = repmat(short_train_blk,NumShortTrainBlks,1);

long_train = tx_freqd_to_timed(LongTrain);
long_train_syms = [long_train(fftlen-2*gilen+1:fftlen,:); long_train; long_train];
preamble = [short_train_blks; long_train_syms];


%% 画图，分别画出 short training、long training 和两者接到一起后的实部虚部图
figure('Name','short training');
subplot(2,1,1);
plot(real(short_train_blks));
title('Subplot 1: real')
subplot(2,1,2);
plot(imag(short_train_blks));
title('Subplot 2: imag');

figure('Name','long training');
subplot(2,1,1);
plot(real(long_train_syms));
title('Subplot 1: real')
subplot(2,1,2);
plot(imag(long_train_syms));
title('Subplot 2: imag');

figure('Name','preamble');
subplot(2,1,1);
plot(real(preamble));
title('Subplot 1: real')
subplot(2,1,2);
plot(imag(preamble));
title('Subplot 2: imag');