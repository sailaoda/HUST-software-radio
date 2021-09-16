function detected_packet = test_rx_find_packet_edge(rx_signal)

win_size = 700;   % 搜索窗大小 (理论上大于噪声长度500就行) 
LTB = 16;   % 每个短训练序列符号长度LTB

% 一次性计算所有相邻符号相关性
xcorr = rx_signal(1:win_size+2*LTB).* ...
              conj(rx_signal(1*LTB+1:win_size+3*LTB));  %(732,1)
% (1:700+2*16)   .*   (1*16+1:700+3*16    =    1;732  .*  17:748

%-------------------------------------------------------------------------
% 逐对计算所有相邻符号相关性mn(的分子|Cn|)
Cn_xcorr = zeros(700,1);
for i = 1:700
    recorder = 0;
    for j = i : (i+2*LTB- 1)     
        recorder = recorder + (xcorr(j+1));      
    end
    Cn_xcorr(i) = abs(recorder);
end
%-------------------------------------------------------------------------
% 逐对计算所有相邻符号相关性mn(的分母Pn)
rx_pwr = abs(rx_signal(1*LTB+1 : win_size+3*LTB)).^2 ;   %17-748
Pn_xcorr = zeros(700,1);
for i = 1:700
    recorder = 0;
    for j = i : (i+2*LTB-1)                  
        recorder = recorder + rx_pwr(j+1); 
    end
    Pn_xcorr(i) = recorder;
end
%-------------------------------------------------------------------------
                  
% 一次性计算所有相邻符号相关性mn=|Cn|/Pn
x_len = length(Cn_xcorr);    % 700*1
mn = Cn_xcorr(1:x_len)./Pn_xcorr(1:x_len);    
plot(mn);    % 绘图

% 判断有无检测到包
threshold = 0.75;   % 判决门限值   
thres_idx = find(mn > threshold);  % 查询满足条件(相关性大于门限值)元素的id
if isempty(thres_idx)    
  thres_idx = 1;        
else   
  thres_idx = thres_idx(1);   % 若有多个id满足条件，则取首个作为检测到包的起点
end

% 根据id取出数据包
detected_packet = rx_signal(thres_idx:length(rx_signal));   