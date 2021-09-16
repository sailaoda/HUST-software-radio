M = 16;                 % Modulation order
k = log2(M);            % Bits per symbol
snrdB = 20;      % Eb/No values (dB)
numSymPerFrame = 100;   % Number of QAM symbols per frame

dataIn = randi([0 1],numSymPerFrame,k);
dataSym = bi2de(dataIn);

% QAM modulate 
txSig = qammod(dataSym,M);

% Pass through AWGN channel
rxSig = awgn(txSig,snrdB,'measured');

% Demodulate the noisy signal
rxSym = qamdemod(rxSig,M);

% Convert received symbols to bits
dataOut = de2bi(rxSym,k);

% Calculate the number of bit errors
nErrors = biterr(dataIn,dataOut);