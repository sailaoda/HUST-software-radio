ShortTrain = sqrt(13/6)*[0 0 1+j 0 0 0 -1-j 0 0 0 1+j 0 0 0 -1-j 0 0 0 -1-j 0 ...
 0 0 1+j 0 0 0 0 0 0 -1-j 0 0 0 -1-j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0];

UsedSubcIdx = [7:32 34:59];
resample_patt=[33:64 1:32];

syms_into_ifft = zeros(64, 1);
syms_into_ifft(UsedSubcIdx) = ShortTrain;
syms_into_ifft(resample_patt) = syms_into_ifft;

time_syms = ifft(syms_into_ifft);