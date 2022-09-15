img = imread('trans.JPG');
ref = imread('refer.jpg');
img = im2double(img);
ref = im2double(ref);

%Color Styoe Transfer
[height, width, ~] = size(ref);
color_thres = [300, 880, 90, 420];
color_transfer_ref = ref(color_thres(3):color_thres(4), color_thres(1):color_thres(2), :);
img = Reinhard(img, color_transfer_ref);

%Mask Generate
mask_thres = [296, 888, 86, 453];
mask1 = zeros(height, width);
mask1(mask_thres(3):mask_thres(4), mask_thres(1):mask_thres(2)) = 1;
mask2 = load('mask2.mat').BW2;
mask = mask1 .* mask2;

%Light Simulation
img = imresize(img, [mask_thres(4)-mask_thres(3)+1 mask_thres(2)-mask_thres(1)+1], 'bicubic');
light = Normalize(fspecial('gaussian', [125, 125], 20));
light_pos = [94, 232, 397, 505, 35, 331];
for i = 1:4
    img(1:light_pos(5)+62, light_pos(i)-62:light_pos(i)+62, :) = img(1:35+62, light_pos(i)-62:light_pos(i)+62, :) .* (1 + light(29:125, :) / 1.5);
    img(light_pos(6)-62:368, light_pos(i)-62:light_pos(i)+62, :) = img(light_pos(6)-62:368, light_pos(i)-62:light_pos(i)+62, :) .* (1 + light(1:100, :) / 1.5);
end

%Final Image Transfer
result = zeros(height, width, 3);
result(mask_thres(3):mask_thres(4), mask_thres(1):mask_thres(2), :) = img;
result = result .* mask;
result = result + (1 - mask) .* ref;

imshow(result);
imwrite(result, 'result_arcade.png');

function result = Reinhard (img, ref)
    img = rgb2lab(img);
    ref = rgb2lab(ref);
    img_mean = squeeze(mean(mean(img)));
    ref_mean = squeeze(mean(mean(ref)));
    img_std = squeeze(std(std(img)));
    ref_std = squeeze(std(std(ref)));
    [H, W, C] = size(img);
    for i = 1:H
        for j = 1:W
            for k = 1:C
                t = img(i,j,k);
                t = (t - img_mean(k)) * (ref_std(k) / img_std(k)) + ref_mean(k);
                img(i,j,k) = t;
            end
        end
    end
    result = lab2rgb(img);
end

function results = Normalize(Image)
    maxNum = max(max(Image));
    minNum = min(min(Image));
    results = (Image - minNum) / (maxNum - minNum);
end
