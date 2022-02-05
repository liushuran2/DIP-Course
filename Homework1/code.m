% 数字图像处理第一次作业
clear; 
clc;
close all;
main_dir = 'images/'; % 源图片放置在images文件夹中
file_type = '.jpg'; % 图片文件类型为jpg

%% 读取文件夹中文件，且做尺寸调整(保持长宽比) 统一图片到同一大小 （空白区域用黑色）。例如，所有图片均为 600 x 1000(max_Y) x 3
image_files = dir([main_dir,'*',file_type]);
len = length(image_files);
image_collect = {}; % 将resize后的图片放到该元胞数组中
max_Y = 0;

for i = 1:len
    image_name{i} = image_files(i).name;
    image = imread([main_dir, image_name{i}]);
    image = im2double(image);
    [height, width, channel] = size(image);
    width = width / height * 600;
    scale = 600 / height;
    image = imresize(image, scale, 'bicubic');
    if width > max_Y
        max_Y = width;
    end
    image_collect{i} = image;
end

for i = 1:len
    back_bg = zeros(600, max_Y, 3);
    [height, width, channel] = size(image_collect{i});
    start_pos = (max_Y - width) / 2 + 1;
    end_pos = (max_Y + width) / 2;
    back_bg(:, start_pos:end_pos, :) = image_collect{i};
    image_collect{i} = back_bg;
end

%% 建立新文件夹（之后方便将保存的视频帧存到该文件夹中）
new_main_dir = 'video_images/';
if ~exist(new_main_dir,'dir')
    mkdir(new_main_dir);
end

%% 将处理的图片集合 image_collect 进行“动画特效”处理， 至少满足作业要求(两个灰度变换类 + 两个几何变换类的动画), 动画顺序可任意调整
figure (1);
set(gcf,'unit','centimeters','position',[5 5 20 20]); % [x_. y_,lenx,leny]
set(gca,'Position',[.2, .2, .7, .65]);
%% 从黑色背景到第一张图片 （淡入淡出，灰度变换类）
black_background = zeros(600, max_Y, 3);
image_idx = 1; % image_collect 的索引
save_idx = 1; % 保存视频帧的序号
for factor = 0:0.02:1
    black_background = image_collect{image_idx} * factor;
    imshow(black_background);
    pause(0.001);
    imwrite(black_background, [new_main_dir, num2str(save_idx,'%05d'),file_type]);
    save_idx = save_idx + 1;
end
%% 淡入淡出 （灰度变换类）
image_start = image_collect{image_idx};
image_end = image_collect{image_idx + 1};
for factor = 0:0.02:1
    current_frame = image_start * (1 - factor) + image_end * factor;
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end
image_idx = image_idx + 1;
%% 棋盘格淡入淡出 （灰度变换类）
unit_checker = 100;
x_checker = ceil(600 / unit_checker / 2);
y_checker = ceil(max_Y / unit_checker / 2);
checker = checkerboard(unit_checker, x_checker, y_checker) > 0.5;
checker = checker(1:600, 1:max_Y);
image_start = image_collect{image_idx};
image_end = image_collect{image_idx + 1};
for factor = 0:0.02:1
    current_frame = image_start .* checker + image_end .* (~checker) * factor + image_start .* (~checker) * (1 - factor);
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end
for factor = 0:0.02:1
    current_frame = image_end .* (~checker) + image_start .* checker * (1 - factor) + image_end .* checker * factor;
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end
image_idx = image_idx + 1;
%% 按方向淡入淡出 （灰度变换类）
image_start = image_collect{image_idx};
image_end = image_collect{image_idx + 1};
speed = 5;
adjust = (1:1:max_Y);
adjust = adjust / max_Y * speed;
for factor = 0:0.02:1
   grey_num = ones(1, max_Y) * factor;
   grey_num = min(grey_num .* (1 + adjust), 1);
   grey_num = repmat(grey_num, 600, 1, 3);
   current_frame = image_end .* grey_num + image_start .* (1 - grey_num);
   imshow(current_frame);
   pause(0.001);
   imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
   save_idx = save_idx + 1;
end
image_idx = image_idx + 1;

%% 3D飞入飞出动画（几何变化类）
image_start = image_collect{image_idx};
image_end = image_collect{image_idx + 1};
for factor = 0.02:0.02:0.98
    angle = factor * 2;
    T_trans = affine2d([(1 - factor) 0 0; 0 (1 - factor) 0; 0 0 1]);
    T_aff = affine2d([1 factor 0; factor 1 0; 0 0 1]);
    T_rotate = affine2d([cos(angle) -sin(angle) 0; sin(angle), cos(angle) 0; 0 0 1]);
    current_frame = imwarp(image_start, T_trans);
    current_frame = imwarp(current_frame, T_rotate);
    current_frame = imwarp(current_frame, T_aff, 'OutputView', imref2d(size(image_start)));
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end
for factor = 0.02:0.02:0.98
    angle = (1 - factor) * 2;
    T_trans = affine2d([factor 0 0; 0 factor 0; 0 0 1]);
    T_aff = affine2d([1 (1 - factor) 0; (1 - factor) 1 0; 0 0 1]);
    T_rotate = affine2d([cos(angle) -sin(angle) 0; sin(angle), cos(angle) 0; 0 0 1]);
    current_frame = imwarp(image_end, T_trans);
    current_frame = imwarp(current_frame, T_rotate);
    current_frame = imwarp(current_frame, T_aff, 'OutputView', imref2d(size(image_start)));
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end
image_idx = image_idx + 1;


%% 暂停20帧
for i = 1:20
    current_frame = image_collect{image_idx}; 
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end

%% 投影翻页动画（几何变化类）
image_start = image_collect{image_idx};
image_end = image_collect{image_idx + 1};
init = [1 1; max_Y 1; max_Y 600; 1 600];
point1 = [200 250; 400 200; 400 400; 200 350];
point2 = [880 200; 1080 250; 1080 350; 880 400];
for factor = 0:0.04:1
    current_point = factor * point1 +  (1 - factor) * init;
    T_proj = fitgeotrans(init, current_point, 'Projective');
    current_frame = imwarp(image_start, T_proj, 'OutputView', imref2d(size(image_start)));
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end
for factor = 0:0.04:1
    current_point = (1 - factor) * point2 + factor * init;
    T_proj = fitgeotrans(init, current_point, 'Projective');
    current_frame = imwarp(image_end, T_proj, 'OutputView', imref2d(size(image_start)));
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end
image_idx = image_idx + 1;

%% 暂停20帧
for i = 1:20
    current_frame = image_collect{image_idx}; 
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end

%% 单页翻转动画 （几何变化类）
image_start = image_collect{image_idx};
image_end = image_collect{image_idx + 1};
for factor = 0:0.02:0.98
    image_resize = imresize(image_start, [600, ceil(max_Y * (1 - factor))], 'bicubic');
    current_frame = zeros(600, max_Y, 3);
    start_pos = ceil((max_Y - ceil(max_Y * (1 - factor))) / 2) + 1;
    end_pos = ceil((max_Y + ceil(max_Y * (1 - factor))) / 2);
    current_frame(:, start_pos:end_pos, :) = image_resize;
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end
for factor = 0.02:0.02:1
    image_resize = imresize(image_end, [600, ceil(max_Y * factor)], 'bicubic');
    current_frame = zeros(600, max_Y, 3);
    start_pos = ceil((max_Y - ceil(max_Y * factor)) / 2) + 1;
    end_pos = ceil((max_Y + ceil(max_Y * factor)) / 2);
    current_frame(:, start_pos:end_pos, :) = image_resize;
    imshow(current_frame);
    pause(0.001);
    imwrite(current_frame, [new_main_dir, num2str(save_idx,'%05d'), file_type]);
    save_idx = save_idx + 1;
end
image_idx = image_idx + 1;



%% 把 new_main_dir 中存好的图片制作成视频
animation = VideoWriter('photo_album','MPEG-4');%待合成的视频(不仅限于avi格式)的文件路径
% 使用VideoWriter建立视频对象 animation，并设置相关参数（例如帧率等）
animation.FrameRate = 25;
open(animation);
image_files = dir([new_main_dir,'*',file_type]);
len = length(image_files);
for i=1:len
    image_name{i} = image_files(i).name; 
    %使用imread 读取视频帧图片，并使用writeVideo函数制作成视频
    current_frame = imread([new_main_dir, image_name{i}]);
    writeVideo(animation, current_frame);
end
close(animation);





