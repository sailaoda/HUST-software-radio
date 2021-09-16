

function [freq_tr_syms, freq_data_syms, freq_pilot_syms] = rx_timed_to_freqd(time_signal)

UsedSubcIdx = [7:32 34:59];
DataSubcIdx = [7:11 13:25 27:32 34:39 41:53 55:59];
PilotSubcIdx = [12 26 40 54];

% Long Training symbols
long_tr_syms = time_signal(1:2*64);
long_tr_syms = reshape(long_tr_syms, 64, 2);

% to frequency domain
freq_long_tr = fft(long_tr_syms)/(64/sqrt(52));
reorder = [33:64 1:32];
freq_long_tr(reorder,:) = freq_long_tr;

% Select training carriers
freq_tr_syms = freq_long_tr(UsedSubcIdx,:);

% Take data symbols
data_syms = time_signal(129:length(time_signal));

data_sig_len = length(data_syms);
n_data_syms = floor(data_sig_len/80);

% Cut to multiple of symbol period
data_syms = data_syms(1:n_data_syms*80);
data_syms = reshape(data_syms, 80, n_data_syms);
% remove guard intervals
data_syms(1:16,:) = [];

% perform fft
freq_data = fft(data_syms)/(64/sqrt(52));

%Reorder pattern is [33:64 1:32]
freq_data(reorder,:) = freq_data;

%Select data carriers
freq_data_syms = freq_data(DataSubcIdx,:);

%Select the pilot carriers
freq_pilot_syms = freq_data(PilotSubcIdx,:);
