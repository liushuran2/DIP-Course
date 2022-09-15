img = imread('trans.jpg');
ref = imread('refer.jpg');
img = im2double(img);
ref = im2double(ref);

%% Left Image

%Mask Generate
mask_point_left = [189,362;333,292;330,416;361,426;364,425;363,480;360,597;181,626];
mask1 = poly_mask(ref, mask_point_left);
mask2 = load('mask2.mat').BW;
mask = mask1 .* mask2;

%Affine Transform
affine_point = [189,362;369,273;360,597;181,626];
[height_img, width_img, ~] = size(img);
[height_ref, width_ref, ~] = size(ref);
area_src = [1,1;width_img,1;width_img,height_img;1,height_img];
affine_mat = estimateGeometricTransform(area_src, affine_point, 'projective');
img_left = imwarp(img, affine_mat, 'OutputView', imref2d([height_ref, width_ref]));

%Left Image Transfer
img_left = img_left .* mask;
result = zeros(height_ref, width_ref, 3);
result = result + img_left;
result = result + (1 - mask) .* ref;

%% Right Image
% Image Drawing
img_style = zeros(height_img, width_img, 3);
for i=1:height_img
    for j=1:width_img
        temp=uint8(rand()*(3));
        m=temp / 2;
        n=mod(temp, 2);
        h=mod(double(i - 1) + double(m), double(height_img));
        w=mod(double(j - 1) + double(n), double(width_img));
        if w==0
            w = width_img;
        end
        if h==0
            h = height_img;
        end
        img_style(i,j,:)=img(h,w,:);
    end
end
img = img_style;

%Saturation Adjustment
img = rgb2hsv(img);
img(:, :, 2) = img(:, :, 2) .* 0.7;
img = hsv2rgb(img);

%Image Block Lines
keyPoint_width = [1, 2, 3] * ceil(width_img / 4);
keyPoint_height = [1, 2, 3, 4, 5] * ceil(height_img / 6);
lines = zeros(height_img, width_img);
lineWidth = 2;
for i = 1:3
    lines(:, keyPoint_width(i) - lineWidth:keyPoint_width(i) + lineWidth) = 1;
end
for i = 1:5
    lines(keyPoint_height(i) - lineWidth:keyPoint_height(i) + lineWidth, :) = 1;
end
fs = fspecial('gaussian', [5, 5], 5);
lines = imfilter(lines, fs, 'replicate', 'same');
img = img + lines * 0.2;

%Image Block Gamma
img(:, keyPoint_width(2):keyPoint_width(3), :) = img(:, keyPoint_width(2):keyPoint_width(3), :) .^ 1.3;
img(:, keyPoint_width(3):width_img, :) = img(:, keyPoint_width(3):width_img, :) .^ 1.6;
img(:, keyPoint_width(1):keyPoint_width(2), :) = img(:, keyPoint_width(1):keyPoint_width(2), :) .^0.8;

%Elastic Trasform
% [movingPoints, fixedPoints] = cpselect(img, ref);
movingPoints = load('movingPoints.mat').movingPoints;
fixedPoints = load('fixedPoints.mat').fixedPoints;
elastic_mat = fitgeotrans(movingPoints, fixedPoints, 'polynomial', 2);
img_right = imwarp(img, elastic_mat, 'OutputView', imref2d([height_ref, width_ref]));

%Mask Generate
mask3 = (img_right > 0);
mask_point_right = [378,259;452,240;546,238;621,259;664,282;669,601;624,592;548,584;451,585;376,592];
mask4 = poly_mask(ref, mask_point_right);
mask5 = load('mask5.mat').BW;
mask = mask3 .* mask4 .* mask5;

%Right Image Transfer
img_right = img_right .* mask;
result = img_right + (1 - mask) .* result;
imshow(result);
imwrite(result, 'result_theatre.png');

function result = poly_mask(img,area)
    [height, width, ~] = size(img);
    result = zeros(height, width);
    for i = 1:height
        for j = 1:width
            if inpolygon(j,i,area(:,1),area(:,2))
                result(i,j) = 1;
            end
        end
    end
end