function detected_packet = rx_find_packet_edge(rx_signal)

search_win = 800;
D = 16;

% Calculate the delayd correlation
delay_xcorr = rx_signal(1:search_win+2*D).*conj(rx_signal(1*D+1:search_win+3*D));

% Moving average of the delayed correlation
ma_delay_xcorr = abs(filter(ones(1,2*D), 1, delay_xcorr));

% Moving average of received power
ma_rx_pwr = filter(ones(1,2*D), 1, abs(rx_signal(1*D+1:search_win+3*D)).^2);

% The decision variable
delay_len = length(ma_delay_xcorr);
ma_M = ma_delay_xcorr(1:delay_len)./ma_rx_pwr(1:delay_len);

% remove delay samples
ma_M(1:2*D) = [];

threshold = 0.75;

thres_idx = find(ma_M > threshold);
if isempty(thres_idx)
  thres_idx = 1;
else
  thres_idx = thres_idx(1);
end


detected_packet = rx_signal(thres_idx:length(rx_signal));
