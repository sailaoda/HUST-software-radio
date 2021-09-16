function time_syms = tx_freqd_to_timed(mod_ofdm_syms) 
num_symbols = size(mod_ofdm_syms,2);

UsedSubcIdx = [7:32 34:59];
resample_patt=[33:64 1:32];

syms_into_ifft = zeros(64, num_symbols);
syms_into_ifft(UsedSubcIdx,:) = mod_ofdm_syms;

syms_into_ifft(resample_patt,:) = syms_into_ifft;

% Convert to time domain
time_syms = sqrt(64)*ifft(sqrt(64/52)*syms_into_ifft);