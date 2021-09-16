function out_signal = frequencysync(transmit,fs)
    len = length(transmit);
    pha=zeros(1,1);
    D = 16;%长度为16的窗口
    pha=0;
    for i=1:(len-D-20)
    %每个数据与d个数据后的数据共轭相乘，求总和
    pha=pha+transmit(19+i).*conj(transmit(i+D));
    end 

    cfo_est = -angle(pha) / (2*D*pi/fs);%求估计出的频偏
    cfo = cfo_est/fs*[0:len-1];%加频偏 
    %[0:total_length-1]/fs=nTs ▲f=0.2*fs/fftlen
    phase_shift = exp(-j*2*pi*cfo)';
    out_signal= transmit.*phase_shift;%将频偏加到传输的信号上