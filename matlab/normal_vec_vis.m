x = 0:pi/100:6*pi;
y = sin(x);
%vx = 0;
%p1 = [vx sin(vx)];
%p2 = [vx-cos(vx) sin(vx)+sin(vx)];
%dp = p2-p1;
%hold off;
%quiver(p1(1),p1(2),dp(1),dp(2),0)
%hold on;
plot(x,y);
xlim([-2 20]);
ylim([-2 2]);