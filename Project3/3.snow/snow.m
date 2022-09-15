img = imread('trans.jpg');
ref = imread('ref_1.png');
black = imread('black_1.png');
img = im2double(img);
ref = im2double(ref);
black = im2double(black);

% Mask Generate
[height, width, ~] = size(ref);
ROI = [160,823,93,627];
ROI_mask = zeros(height, width);
ROI_mask(ROI(3):ROI(4), ROI(1):ROI(2)) = 1;
BW_mask = load('BW.mat').BW;
mask = BW_mask .* ROI_mask;
mask = ~(bwareaopen(~mask, 64, 8));

% Edge Feather
mask_init = mask;
se = strel('disk', 60);
mask_edge = mask - imerode(mask, se);
fs = fspecial('gaussian', [30,30], 30);
mask_edge = Normalize(imfilter(mask_edge, fs));
se = strel('disk', 30);
mask = imerode(mask, se) + mask_edge;
mask(mask > 1) = 1;

% % Snow Generate
mask_snow = zeros(height, width);
amount = fix(height * width * 0.002);
for j=1:amount
    x = randi(height,1,1);    
    y = randi(width,1,1);
    mask_snow(x,y)=1;
end
mask_snow = mask_snow .* mask_init;
se = strel('disk', 2);
mask_snow = imdilate(mask_snow, se);
fs = fspecial('gaussian', [3,3], 5);
mask_snow = imfilter(mask_snow, fs);

% Image Transfer
pic_region = [163,823,93,646];
img = imresize(img, [pic_region(4)-pic_region(3)+1 pic_region(2)-pic_region(1)+1],'bicubic');
result = zeros(height, width, 3);
result(pic_region(3):pic_region(4), pic_region(1):pic_region(2), :) = img;
result = result .* mask;
result = result + (1 - mask) .* black;
result = result + mask_snow * 0.5;
imshow(result);
imwrite(result, 'result_snow.png');

function results = Normalize(Image)
    maxNum = max(max(Image));
    minNum = min(min(Image));
    results = (Image - minNum) / (maxNum - minNum);
end

