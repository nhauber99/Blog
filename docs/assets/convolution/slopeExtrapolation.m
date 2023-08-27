
% AUTHOR: Niklas Hauber
% example script showing linear regression based extrapolation

useSlopeExtrapolation = true;
n = 500; % Size of the array
sigma = 15; % gaussian std dev
kernel_size = 50; % must be odd

% init data
%data = (1:n)/n-0.5;
data = sin((1:n)/90);
data = data + 0.01*randn(1,n);
%data(10:20) = nan;
%data(50:60) = nan;

% init gaussian kernel
half_size = floor(kernel_size / 2);
kernel = zeros(1, kernel_size);
for i = -half_size:half_size
    kernel(i + half_size + 1) = exp(-i^2 / (2 * sigma^2));
end
kernel = kernel / sum(kernel);

blurred = zeros(1, n);

for i = 1:n
    self = data(i);

    valueSum = 0;
    distSum = 0;
    
    s_winv = 0;
    s_w = 0;
    s_xy = 0;
    s_x = 0;
    s_y = 0;
    s_x2 = 0;

    for x = -half_size:half_size
        idx = i + x;
        k = kernel(x + half_size + 1);
        valid_sample = idx>= 1 && idx<=n && ~isnan(data(idx));
        if valid_sample
            y = data(idx);
            valueSum = valueSum + y * k;

            s_w=s_w+k;
            s_xy = s_xy+k*x*y;
            s_x = s_x+k*x;
            s_y = s_y+k*y;
            s_x2 = s_x2+k*x*x;
        elseif useSlopeExtrapolation
            s_winv = s_winv+k;
            distSum = distSum+k*x;
        end
    end
    
    if useSlopeExtrapolation
        slope = (s_w*s_xy - s_x*s_y) / (s_w*s_x2 - s_x*s_x);
        intercept = (s_y-slope*s_x)/s_w;
        blurred(i) = valueSum + s_winv*intercept + distSum*slope;
    else
        blurred(i) = valueSum / s_w;
    end
end

%figure
subplot(2,1,1);
hold off; % to replace last figure
plot(data, 'b', 'DisplayName', 'Original');
hold on;
plot(blurred, 'r', 'DisplayName', 'Blurred');
legend;
subplot(2,1,2);
plot(data-blurred, 'r', 'DisplayName', 'Difference');
%ylim([-0.1 0.11])
legend;
