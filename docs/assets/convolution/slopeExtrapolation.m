
% AUTHOR: Niklas Hauber
% example script showing slope extrapolation

useSlopeExtrapolation = true; 
n = 500; % Size of the array
sigma = 10; % gaussian std dev
kernel_size = 20; % must be odd

% init data
%data = (1:n)/n-0.5;
data = sin((1:n)/80);
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

    weight_sum = 0;
    wsum_xy = 0;
    wsum_x = 0;
    wsum_y = 0;
    wsum_x2 = 0;

    for x = -half_size:half_size
        idx = i + x;
        k = kernel(x + half_size + 1);
        valid_sample = idx>= 1 && idx<=n && ~isnan(data(idx));
        if valid_sample
            y = data(idx);
            valueSum = valueSum + y * k;
            weight_sum=weight_sum+k;
               
            wsum_xy = wsum_xy+k*x*y;
            wsum_x = wsum_x+k*x;
            wsum_y = wsum_y+k*y;
            wsum_x2 = wsum_x2+k*x*x;
        elseif useSlopeExtrapolation
            valueSum = valueSum+self*k;
            distSum = distSum+k*x;
        end
    end
    
    if useSlopeExtrapolation
        slope = (wsum_xy- wsum_x*wsum_y/weight_sum) / (wsum_x2 - wsum_x*wsum_x/weight_sum);
        blurred(i) = valueSum + distSum*slope;
    else
        blurred(i) = valueSum / weight_sum;
    end
end

% Plot the original and blurred arrays
%figure
subplot(2,1,1);
hold off; % to replace last figure
plot(data, 'b', 'DisplayName', 'Original');
hold on;
plot(blurred, 'r', 'DisplayName', 'Blurred');
legend;
subplot(2,1,2);
plot(blurred-data, 'r', 'DisplayName', 'Difference');
legend;
