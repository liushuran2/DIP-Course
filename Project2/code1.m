addpath("D:\Matlab\toolbox\NIfTI_20140122");
addpath("D:\Matlab\toolbox\SliceBrowser");
pic_name = ['4', '5', '7'];

for i = 1:3
   ori_lung = load_nii(['./data/coronacases_org_00', pic_name(i), '.nii']); 
   gt_lung = load_nii(['./data/coronacases_lung_00', pic_name(i), '.nii']);
   img = ori_lung.img;
   gt = gt_lung.img;
   [H, W, D] = size(img);
   seg_lung = zeros(H, W, D);
   acc_lung = zeros(H, W, D);
   
   for depth = 1:D
       img_process = img(:, :, depth);
       gt_process = gt(:, :, depth);
       img_process = im2double(img_process);
       img_process = Normalize(img_process);
       
       %Ground Truth图像二值化
       gt_process = im2double(gt_process);
       gt_process = Normalize(gt_process);
       gt_process = imbinarize(gt_process, 0.1);
       acc_lung(:, :, depth) = gt_process;
       
       % 图像二值化
       level = graythresh(img_process);
       img_process = imbinarize(img_process, level);
       
       % 寻找最大连通域
       maxRegion = findMax(img_process);
       
       % 提取空洞部分
       body = imfill(maxRegion, 'hole');
       lung = body .* (~maxRegion);
       lung = bwareaopen(lung, 32, 8);
       
       % 求最大两片区域并记录
       lungPart1 = findMax(lung);
       lung = lung - lungPart1;
       lungPart2 = findMax(lung);
       lung = lungPart1 + lungPart2;

       seg_lung(:, :, depth) = lung;
   end
   
   % 消除小连通域
   connectRegion = bwconncomp(seg_lung, 26);
   areaPixels = cellfun(@numel,connectRegion.PixelIdxList);
   maxArea = max(areaPixels);
   for regionIndex = 1:connectRegion.NumObjects
       if areaPixels(regionIndex) < maxArea / 2
          seg_lung(connectRegion.PixelIdxList{regionIndex}) = 0; 
       end
   end
   volshow(seg_lung);
   calDice = dice(acc_lung, seg_lung);
   disp(calDice);
   save(['seg_lung_00',pic_name(i),'.mat'], 'seg_lung');
end

function result = findMax(img)
    [L, num] = bwlabel(img, 4);
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