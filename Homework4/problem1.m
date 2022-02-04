% LUT = genLUT();
% imshow(LUT);
% imwrite(LUT, 'LUT_ori.png');

LUT_filter1 = imread('LUT_filter3.jpg');
img = imread('pic1.jpeg');

LUT_filter1 = resize(LUT_filter1);
result = Filter2(img, LUT_filter1);
imshow(result / 255);
imwrite(result / 255, 'result.png');
% LUT_filter1 = im2double(LUT_filter1);
% result = Filter(img, LUT_filter1);
% imshow(result);


function result = resize(filter_input)
    result = uint8(zeros(256,256,256,3));             
    filterResized= uint8(zeros(64,64,64,3));
    for i = 1:64
        index_i = floor((i - 1) / 8 ) * 64;
        index_j = int16(mod(i - 1,8)) * 64;
        for j = 1:64
            for k = 1:64
                filterResized(j,k,i,:) = filter_input(index_i + k,index_j + j, :);
            end
        end
    end
    result(:,:,:,1) = imresize3(filterResized(:,:,:,1),[256,256,256]);
    result(:,:,:,2) = imresize3(filterResized(:,:,:,2),[256,256,256]);
    result(:,:,:,3) = imresize3(filterResized(:,:,:,3),[256,256,256]);
    result = uint8(round(result));
end

function result = Filter2(img, LUT)
    [height, width, ~] = size(img);
    result = zeros(height, width, 3);
    for i = 1:height
       for j = 1:width
           result(i,j,:) = LUT(round(img(i,j,1) + 1) ,round(img(i,j,2) + 1) ,round(img(i,j,3) + 1), :);
       end
    end
end

function result = genLUT()
    block = zeros(64, 64, 2);
    block(:, :, 1) = meshgrid(0:63, 0:63);
    block(:, :, 2) = transpose(block(:, :, 1));
    result = zeros(512, 512, 3);
    for i = 1:8
        for j = 1:8
            index = (i - 1) * 8 + (j - 1);
            left = (i - 1) * 64 + 1;
            right = left + 63;
            top = (j - 1) * 64 + 1;
            down = top + 63;
            result(left:right, top:down, 1:2) = block;
            result(left:right, top:down, 3) = index;
        end
    end
    result = result * 4;
    result = result / 256;
end

function result = Filter(img, LUT)
    [height, width, ~] = size(img);
    result = zeros(height, width, 3);
    for i = 1:height
       for j = 1:width
           indexR = floor(double(img(i, j, 1)) / double(4)) + 1;
           indexG = floor(double(img(i, j, 2)) / double(4)) + 1;
           indexB = floor(double(img(i, j, 3)) / double(4)) + 1;
           index_i = int16(ceil(double(indexB) / double(8)));
           index_j = int16(mod(indexB, 8) + 1);
           left = (index_i - 1) * 64 + 1;
           right = left + 63;
           top = (index_j - 1) * 64 + 1;
           down = top + 63;
           block = LUT(left:right, top:down, :);
           result(i, j, 1) = block(indexG, indexR, 1);
           result(i, j, 2) = block(indexG, indexR, 2);
           result(i, j, 3) = block(32, 32, 3);
       end
    end
end

