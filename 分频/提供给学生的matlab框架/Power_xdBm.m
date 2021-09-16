%%****计算实信号的绝对功率谱*********%%
%%**** x为输入实信号序列,单位为"伏特"*****%%
%%**** fs为输入信号序列的采样率,单位为"MHz"****%%
function [X_Axis1,x4]=Power_xdBm(x,fs)
n=length(x);
if rem(n,2)~=0
    y=x(1:n-1);
    n=n-1;
else
    y=x;
end
w= blackmanharris(n);
y=y.*w';
x1=fft(y,n); 
x2=x1/(sqrt(sum(w.^2)/n));    %有泄漏的能量恢复系数
x2=x2.*conj(x2);
x3=33+10*log10(x2*2/(50*n^2));
x4=x3(1:(n/2));   
X_Axis1=(0:(n/2-1))*fs/n;
figure
plot(X_Axis1,x4,'k');
axis([0,fs/2,-160,10]);
xlabel('频率 (MHz)');
ylabel('功率 (dBm)');
grid on