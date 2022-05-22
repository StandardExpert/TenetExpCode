function y=flower_tree(x1,y1,x2,y2,n)
x1=1;
y1=1;
x2=2;
y2=2;
n=5;


flag=0;

theta=pi/6;

if x2
    
    flag=1;
    
end

if n>1
    
    flower_tree(x1,y1,(2*x1+x2)/3.0,(2*y1+y2)/3.0,n-1);
    
    flower_tree((2*x1+x2)/3.0,(2*y1+y2)/3.0,(2*x2+x1)/3.0,(2*y2+y1)/3.0,n-1);
    
    flower_tree((2*x2+x1)/3.0,(2*y2+y1)/3.0,x2,y2,n-1);
    
    flower_tree((2*x1+x2)/3.0,(2*y1+y2)/3.0,(2*x1+x2)/3.0+sin(pi/2-atan((y2-y1)/(x2-x1))-theta+flag*pi)*sqrt(((y2-y1)^2+(x2-x1)^2)/3),(2*y1+y2)/3.0+cos(pi/2-atan((y2-y1)/(x2-x1))-theta+flag*pi)*sqrt(((y2-y1)^2+(x2-x1)^2)/3),n-1);
    
    flower_tree((2*x2+x1)/3.0,(2*y2+y1)/3.0,(2*x2+x1)/3.0+sin(pi/2-atan((y2-y1)/(x2-x1))+theta+flag*pi)*sqrt(((y2-y1)^2+(x2-x1)^2)/3),(2*y2+y1)/3.0+cos(pi/2-atan((y2-y1)/(x2-x1))+theta+flag*pi)*sqrt(((y2-y1)^2+(x2-x1)^2)/3),n-1);
    
else
    
    x=[x1,x2];
    
    y=[y1,y2];
    
    xx=[(2*x1+x2)/3.0,(2*x1+x2)/3.0+sin(pi/2-atan((y2-y1)/(x2-x1))-theta+flag*pi)*sqrt(((y2-y1)^2+(x2-x1)^2)/3)];
    
    yy=[(2*y1+y2)/3.0,(2*y1+y2)/3.0+cos(pi/2-atan((y2-y1)/(x2-x1))-theta+flag*pi)*sqrt(((y2-y1)^2+(x2-x1)^2)/3)];
    
    xxx=[(2*x2+x1)/3.0,(2*x2+x1)/3.0+sin(pi/2-atan((y2-y1)/(x2-x1))+theta+flag*pi)*sqrt(((y2-y1)^2+(x2-x1)^2)/3)];
    
    yyy=[(2*y2+y1)/3.0,(2*y2+y1)/3.0+cos(pi/2-atan((y2-y1)/(x2-x1))+theta+flag*pi)*sqrt(((y2-y1)^2+(x2-x1)^2)/3)];
    
    line(x,y);
    
    line(xx,yy);
    
    line(xxx,yyy);
    
end

axis equal