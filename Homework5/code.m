name = 'r3.bmp';
img = imread(name);
img = im2double(img);

img_init = img;

% 参数设置
if strcmp(name, 'r1.bmp')
    binarizeParam = 0.56;
    openParam = 64;
    greyParam = 126;
    maskParam = 20;
    iterParam1 = 12;
    iterParam2 = 8;
end
if strcmp(name, 'r2.bmp')
    binarizeParam = 0.58;
    openParam = 64;
    greyParam = [124, 125];
    maskParam = 30;
    iterParam1 = 12;
    iterParam2 = 8;
end
if strcmp(name, 'r3.bmp')
    binarizeParam = 0.58;
    openParam = 64;
    greyParam = 126;
    maskParam = 10;
    iterParam1 = 10;
    iterParam2 = 5;
end
    
% 图像二值化
img = gaussFilter(img);
img = imbinarize(img, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', binarizeParam);

img = bwareaopen(img, openParam, 8);
img = ~img;
img = bwareaopen(img, openParam, 8);
imwrite(~img, 'step1.png');

% 图像细化
img = bwmorph(img, 'thin', inf);
img = bwareaopen(img, 5, 8);
imshow(~img);
imwrite(~img, 'step2.png');

% 去除短接、毛刺、桥接
img = Cutting(img, iterParam1, iterParam2);
img = bwareaopen(img, 5, 8);
imshow(~img);
imwrite(~img, 'step3.png')

% 细节点标注
img = Point(img, img_init, greyParam, maskParam);

function result = Point(img, img_init, greyParam, maskParam)
    dir = zeros(9,2);
    dir(:, 1) = [-1,-1,-1,0,1,1,1,0,-1];
    dir(:, 2) = [-1,0,1,1,1,0,-1,-1,-1];
    [height, width] = size(img);
    cn = zeros(height, width);
    for i = 2:height - 1
        for j = 2:width - 1
            if (img(i, j) == 0)
                continue
            end
            for x = 1:8
                cn(i,j) = cn(i,j)+ abs(img(i+dir(x,1),j+dir(x,2)) - img(i+dir(x+1,1),j+dir(x+1,2)));
            end
        end
    end
    [endPoint_x, endPoint_y] = find(cn == 2);  %端点
    [branPoint_x, branPoint_y] = find(cn == 6);  %分支点
    
    if length(greyParam) > 1
        ROI_mask = (img_init == greyParam(1) / 255);
        ROI_mask = ROI_mask | (img_init == greyParam(2) / 255);
    else
        ROI_mask = (img_init == greyParam / 255);
    end
    ROI_mask = bwareaopen(ROI_mask, 32, 8);
    se = strel('disk', maskParam);
    ROI_mask = imdilate(ROI_mask, se);
    for i = length(endPoint_x):-1:1
        if (ROI_mask(endPoint_x(i), endPoint_y(i)) == 1)
            endPoint_x(i) = [];
            endPoint_y(i) = [];
        end
    end
    
    img_plot = ~img;
    figure(1);
    imshow(img_plot);
    hold on;
    for idx = 1:length(endPoint_x)
        rectangle('Position', [endPoint_y(idx), endPoint_x(idx), 3, 3], 'LineWidth', 1, 'EdgeColor', 'r');
    end
    for idx = 1:length(branPoint_x)
        rectangle('Position', [branPoint_y(idx), branPoint_x(idx), 3, 3], 'LineWidth', 1, 'EdgeColor', 'b');
    end
    saveas(1, 'step4.png');
    result = img_plot;
end


function result = Cutting(img, iterParam1, iterParam2)
    endpoint = zeros(3, 3, 8);
    endpoint(:, :, 1) = reshape([0,1,0,-1,1,-1,-1,-1,-1], [3,3]);
    endpoint(:, :, 2) = reshape([-1,-1,0,-1,1,1,-1,-1,0], [3,3]);
    endpoint(:, :, 3) = reshape([-1,-1,-1,-1,1,-1,0,1,0], [3,3]);
    endpoint(:, :, 4) = reshape([0,-1,-1,1,1,-1,0,-1,-1], [3,3]);
    endpoint(:, :, 5) = reshape([1,-1,-1,-1,1,-1,-1,-1,-1], [3,3]);
    endpoint(:, :, 6) = reshape([-1,-1,1,-1,1,-1,-1,-1,-1], [3,3]);
    endpoint(:, :, 7) = reshape([-1,-1,-1,-1,1,-1,-1,-1,1], [3,3]);
    endpoint(:, :, 8) = reshape([-1,-1,-1,-1,1,-1,1,-1,-1], [3,3]);
    iter_time = iterParam1;
    [height, width] = size(img);
    img_init = img;
    for i = 1:iter_time
        hit = zeros(height, width, 8);
        for j = 1:8
           hit(:, :, j) = bwhitmiss(img, endpoint(:, :, j));
        end
        for j = 1:8
           img = img - hit(:, :, j); 
        end
    end

    img_rec = bwmorph(img, 'endpoints', inf);
    se = strel('disk', iterParam2);
    img_rec = imdilate(img_rec, se) & (img_init);
    
    result = img | img_rec;
    imshow(result);
end

function Period = gaussFilter(Period)
    filter = fspecial('gaussian', [3, 3], 1);
    Period = imfilter(Period, filter, 'replicate', 'same');
end

function results = Normalize(Image)
    maxNum = max(max(Image));
    minNum = min(min(Image));
    results = (Image - minNum) / (maxNum - minNum);
end