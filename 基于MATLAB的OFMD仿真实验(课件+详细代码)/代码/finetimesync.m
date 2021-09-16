function fine_time_est = finetimesync(transmit,longTrain);
        i_matrix=zeros(64,1);
        j_matrix=zeros(71,1);
        for j=150:220    %正确的同步位置在160+32+1处，选择范围包括193
        for i=1:64       %长训练序列的64位
            i_matrix(i)=transmit(j-1+i).*conj(longTrain(i)); %接受序列与长训练序列共轭相乘
            j_matrix(j-149)=j_matrix(j-149)+i_matrix(i);    %以每一个bit为起始计算出一个和
        end
        end
        [a,b] = max(abs(j_matrix));        %求和最大的，相关程度最高
        fine_time_est = 149 +b;