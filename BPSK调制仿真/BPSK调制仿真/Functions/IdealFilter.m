function y = IdealFilter(x,sys_param)

% ÀíÏëÆµÂÊÂË²¨Æ÷

freq_ratio = sys_param.band*sys_param.sampling_interval*2;

fft_x = fft(x);
len = length(x);

stop_point = round(len*freq_ratio);

fft_x(stop_point:len-stop_point+2) = zeros(1,len-2*stop_point+3);

y = ifft(fft_x);

plotFFT(y,sys_param);
