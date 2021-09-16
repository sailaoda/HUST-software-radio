M = 4;                 % Modulation order
k = log2(M);            % Bits per symbol
numSymPerFrame = 100;   % Number of QAM symbols per frame

dataIn = randi([0 1],numSymPerFrame,k);
dataSym = bi2de(dataIn);

% QAM modulate 
txSig = qammod(dataSym,M);
scatterplot(txSig);

% introducing CFO in time domain
cfo = 0.01;
time = [0:length(txSig)-1]';
rxSig = txSig.*exp(j*2*pi*cfo*time);
scatterplot(rxSig);
