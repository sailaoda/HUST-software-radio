

function fine_time_est = rx_fine_time_sync(input_signal,long_train);

%timing search window size
start_search=150;
end_search=210;
time_corr_long = zeros(1,end_search-start_search+1);

for idx=start_search:end_search
    time_corr_long(idx-start_search+1) = sum((input_signal(idx:idx+63).*conj(long_train)));
end

[max_corr,long_search_idx] = max(abs(time_corr_long));

fine_time_est = start_search-1 + long_search_idx;




