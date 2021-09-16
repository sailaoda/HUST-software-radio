function xn=four2two(yn)

y=yn; ymin=min(y);
ymax=max(y);
yn=(y-ymin)*3/(ymax-ymin); 

%设置门限电平，判决
I0=find(yn< 0.5); 			
yn(I0)=zeros(size(I0));
I1=find(yn>=0.5 & yn<1.5); 	
yn(I1)=ones(size(I1));
I2=find(yn>=1.5 & yn<2.5); 	
yn(I2)=ones(size(I2))*2;
I3=find(yn>=2.5); 			
yn(I3)=ones(size(I3))*3;
%一位四进制码元转换为两位二进制码元
T=[0 0;0 1;1 1;1 0];	
n=length(yn); 
for i=1:n
   xn(i,:)=T(yn(i)+1,:);
end  
xn=xn'; 
xn=xn(:); 
xn=xn';
