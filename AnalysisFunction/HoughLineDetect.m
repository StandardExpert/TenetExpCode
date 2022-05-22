function I_out=HoughLineDetect(Img,thresholdValue)
%input: 
%       img:输入图像；
%       thresholdValue：hough阈值；
%output: 
%       I_out:检测直线结果，二值图像；
    if  ~exist( 'thresholdValue', 'var' )
        thresholdValue = 150;
    end
    
    if length(size(Img))>2
        I_gray=rgb2gray(Img); %如果输入图像是彩色图，需要转灰度图
    else
        I_gray=Img;
    end
    [x,y]=size(I_gray);   %图像大小
    BW=edge(I_gray);  %计算图像边缘

    rho_max=floor(sqrt(x^2+y^2))+1; %由图像坐标算出ρ最大值，结果取整并加1，作为极坐标系最大值
    AccArray=zeros(rho_max,180);       %初始化极坐标系的数组
    Theta=0:pi/180:pi;                           %定义θ数组，范围从0-180度

    for n=1:x
        for m=1:y
            if BW(n,m)==1
                for k=1:180
                    %hough变换方程求ρ值
                    rho=(m*cos(Theta(k)))+(n*sin(Theta(k)));
                    %为了防止ρ值出现负数，将ρ值与ρ最大值的和的一半作为ρ的坐标值
                    rho_int=round(rho/2+rho_max/2);
                    %在极坐标中标识点，相同点累加
                    AccArray(rho_int,k)=AccArray(rho_int,k)+1;
                end
            end
        end
    end

    %利用hough变换提取直线
    K=1;                             %存储数组计数器
%     thresholdValue=200;   %设定直线的最小值。
    for rho=1:rho_max      %在hough变换后的数组中搜索
        for theta=1:180
            if AccArray(rho,theta)>=thresholdValue 
                case_accarray_rho(K)=rho;  
                case_accarray_theta(K)=theta;
                K=K+1;
            end
        end
    end

    %将直线提取出来,输出图像数组I_out
    I_out=zeros(x,y);
    for n=1:x
        for m=1:y
             if BW(n,m)==1
                 for k=1:180
                    rho=(m*cos(Theta(k)))+(n*sin(Theta(k)));
                    rho_int=round(rho/2+rho_max/2);
                    for a=1:K-1
                        if rho_int==case_accarray_rho(a)&&k==case_accarray_theta(a)
                            I_out(n,m)=BW(n,m); 
                        end
                    end
                 end
             end
        end
    end

    figure,imshow(Img);title('输入图像');
    % figure,imshow(BW);title('edge处理后的边界图');
    figure,imshow(I_out);title('Hough变换检测出的直线');
    
end
% ————————————————
% 版权声明：本文为CSDN博主「Naruto_Q」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
% 原文链接：https://blog.csdn.net/piaoxuezhong/article/details/78534545