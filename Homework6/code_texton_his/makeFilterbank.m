function fb = makeFilterbank(numfb)
% Make filter bank. It is convinient to represent this as a [N N 8] array.

% Random filterbank. You should replace this with your implementation.
hsize = 20;
sigma = 3;
fb = zeros(hsize, hsize, numfb);
gaussian_a = fspecial('gaussian', hsize, sigma);
gaussian_b = fspecial('gaussian', hsize, sigma - 1);
gaussian_c = fspecial('gaussian', hsize, sigma - 2);
prewitt_f = fspecial('prewitt');
gaussian_a = conv2(gaussian_a, prewitt_f, 'same');
gaussian_b = conv2(gaussian_b, prewitt_f, 'same');
gaussian_c = conv2(gaussian_c, prewitt_f, 'same');
fb(:, :, 1) = gaussian_a;
fb(:, :, 2) = gaussian_b;
fb(:, :, 3) = gaussian_c;
fb(:, :, 4) = transpose(gaussian_a);
fb(:, :, 5) = transpose(gaussian_b);
fb(:, :, 6) = transpose(gaussian_c);
gaussian_lap_a = fspecial('log', hsize, sigma);
gaussian_lap_b = fspecial('log', hsize, sigma - 2);
fb(:, :, 7) = gaussian_lap_a;
fb(:, :, 8) = gaussian_lap_b;
if numfb == 14
   fb(:, :, 9) = imrotate(gaussian_a, 45, 'crop'); 
   fb(:, :, 10) = imrotate(gaussian_b, 45, 'crop');
   fb(:, :, 11) = imrotate(gaussian_c, 45, 'crop');
   fb(:, :, 12) = imrotate(gaussian_a, -45, 'crop'); 
   fb(:, :, 13) = imrotate(gaussian_b, -45, 'crop');
   fb(:, :, 14) = imrotate(gaussian_c, -45, 'crop');
end
end

function results = Normalize(Image)
    maxNum = max(max(Image));
    minNum = min(min(Image));
    results = (Image - minNum) / (maxNum - minNum);
end