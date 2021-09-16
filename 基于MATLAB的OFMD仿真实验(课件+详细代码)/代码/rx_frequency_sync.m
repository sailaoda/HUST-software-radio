function out_signal = rx_frequency_sync(rx_signal,fs)
           
pkt_det_offset = 20;

% averaging length
rlen = 160-pkt_det_offset;

% short training symbol periodicity
D = 16;

phase = rx_signal(pkt_det_offset:pkt_det_offset+rlen-D).* ...
  conj(rx_signal(pkt_det_offset+D:pkt_det_offset+rlen));

% add all estimates 
phase = sum(phase);

freq_est = -angle(phase) / (2*D*pi/fs);
radians_per_sample = 2*pi*freq_est/fs;
time_base = 0:length(rx_signal)-1;
correction = exp(-j*(radians_per_sample)*time_base);             
out_signal = rx_signal.*correction.';