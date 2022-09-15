addpath("D:\Matlab\toolbox\NIfTI_20140122");
addpath("D:\Matlab\toolbox\SliceBrowser");
pic_name = ['4', '5', '7'];

for i = 1:3
   ori_trach = load_nii(['./data/coronacases_org_00', pic_name(i), '.nii']); 
   gt_trach = load_nii(['./data/coronacases_trachea_00', pic_name(i), '.nii']);
   img = ori_trach.img;
   gt = gt_trach.img;
   [H, W, D] = size(img);
   seg_trach = zeros(H, W, D);
   acc_trach = zeros(H, W, D);
   
   for depth = 2:D
       img_process = img(:, :, depth);
       gt_process = gt(:, :, depth);
       img_process = im2double(img_process);
       img_process = Normalize(img_process);
       
       %Ground Truth图像二值化
       gt_process = im2double(gt_process);
       gt_process = Normalize(gt_process);
       gt_process = imbinarize(gt_process, 0.1);
       acc_trach(:, :, depth) = gt_process;
       
       % 图像二值化
       level = graythresh(img_process);
       img_process = imbinarize(img_process, level);
       
       % 寻找最大连通域
       maxRegion = findMax(img_process);
       
       % 提取空洞部分
       body = imfill(maxRegion, 'hole');
       trach = body .* (~maxRegion);
       trach = bwareaopen(trach, 32, 8);
       
       img_erode = zeros(H, W);
       for disksize = 1:9
           img_erode = img_erode + multi_erode(trach, disksize);
       end
       trach = (img_erode ~= 0);
       trach = bwareaopen(trach, 16, 8);
       
       trach = trach';
       seg_trach(1:H-2, 1:W-1, depth - 1) = trach(3:H, 2:W);
   end
   
%    三维连通域去噪
   se = strel('cube',3);
   seg_trach = imerode(seg_trach, se);

   connectRegion = bwconncomp(seg_trach, 26);
   areaPixels = cellfun(@numel,connectRegion.PixelIdxList);
   maxArea = max(areaPixels);
   for regionIndex = 1:connectRegion.NumObjects
       if areaPixels(regionIndex) < maxArea
          seg_trach(connectRegion.PixelIdxList{regionIndex}) = 0; 
       end
   end
   
   se = strel('cube',3);
   seg_trach = imdilate(seg_trach, se);
   
   % 计算结果
   volshow(seg_trach);
   calDice = dice(acc_trach, seg_trach);
   disp(calDice);
   save(['seg_trach_00',pic_name(i),'.mat'], 'seg_trach');
end

function result = multi_erode(img, disksize)
    se = strel('disk', disksize);
    img_ori = img;
    img = imerode(img, se);
    [L, num] = bwlabel(img, 4);
    for idx = 1:num
       if sum(sum(L == idx)) > 500
           img = (~(L == idx)) .* img;
       end
    end
    img = imdilate(img, se);
    result = img .* img_ori;
end

function result = findMax(img)
    [L, num] = bwlabel(img, 8);
    maxArea = 0;
    [H, W] = size(img);
    result = zeros(H, W);
    for regionIndex = 1:num
       area = sum(sum(L == regionIndex));
       if area > maxArea
            maxArea = area;
            result = (L == regionIndex);
       end
    end
end

function results = Normalize(Image)
    maxNum = max(max(Image));
    minNum = min(min(Image));
    results = (Image - minNum) / (maxNum - minNum);
end