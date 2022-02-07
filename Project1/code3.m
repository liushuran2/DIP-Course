filename = '3.bmp';

img = imread(filename);
img = im2double(img);

%参数设置
segLength = 24;
DFTLength = 64;
fingerParam = 42;
gaborK = 28;
deleteArea = 256;
varMin = 0.15;
varMax = 0.8;

%方差图滤波
[ROI_var_t, ROI_var_f] = varFilter(img, segLength, DFTLength, varMin, varMax);

%生成方向图
[ROI, Angle, Period]= fingerDetector(img, segLength, DFTLength, fingerParam);

%前景分割综合结果
ROI = ROI_var_f .* ROI .* ROI_var_t;
ROI = bwareaopen(ROI, deleteArea, 8);

%方向图、频率图滤波
Angle = angleFilter(Angle);
Period = periodFilter(Period, 7, 3);
Period = Normalize(Period);

%图像增强
img = gaborFilter(img, ROI, Angle, Period, segLength, DFTLength, gaborK);

%增强后图像平滑
img = Normalize(img);
img = periodFilter(img, 5, 1);
img = Normalize(img);
img = imbinarize(img, 0.5);
img = bwareaopen(img, 64, 8);

figure(1);
hold on;
imshow(img);
imwrite(img, 'img_enhanced.png');
DrawDir(1, Angle, segLength, 'r', ROI);
Period_inter = imresize(Period, segLength, 'nearest');
imwrite(Period_inter, 'Period.png');

function [ROI_var_t, ROI_var_f] = varFilter(img, segLength, DFTLength, minVar, maxVar)
    [height, width] = size(img);
    segNum_h = ceil(height / segLength);
    segNum_w = ceil(width / segLength);
    var_t = zeros(segNum_h, segNum_w);
    var_f = zeros(segNum_h, segNum_w);
    for index_h = 1:segNum_h
        for index_w = 1:segNum_w
            wStart = max(1, (index_w-1) * segLength + 1 - (DFTLength / 4));
            wEnd = min(width, (index_w-1) * segLength - (DFTLength / 4) + DFTLength);
            hStart = max(1, (index_h-1) * segLength + 1 - (DFTLength / 4));
            hEnd = min(height, (index_h-1) * segLength - (DFTLength / 4) + DFTLength);
            segImg = img(hStart:hEnd, wStart:wEnd);
            var_t(index_h, index_w) = var(segImg(:));
            segImg_f = abs(fftshift(fft2(segImg)));
            var_f(index_h, index_w) = var(segImg_f(:));
        end
    end
    var_t = periodFilter(var_t, 5, 1);
    var_f = periodFilter(var_f, 5, 1);
    var_t = Normalize(var_t);
    var_f = Normalize(var_f);
    var_f = var_f < maxVar;
    var_t = var_t > minVar;
    ROI_var_t = var_t;
    ROI_var_f = var_f;
end

function Angle = angleFilter(Angle)
    angleCos = cos(Angle * 2 * pi / 180);
    angleSin = sin(Angle * 2 * pi / 180);
    filter = fspecial('gaussian', [5, 5], 1);
    angleCos = imfilter(angleCos, filter, 'replicate', 'same');
    angleSin = imfilter(angleSin, filter, 'replicate', 'same');
    angleTan = atan2(angleSin, angleCos);
    Angle = angleTan / 2 / pi * 180;
end

function Period = periodFilter(Period, param1, param2)
    filter = fspecial('gaussian', [param1, param1], param2);
    Period = imfilter(Period, filter, 'replicate', 'same');
end

function img_gabor = gaborFilter(img, ROI, Angle, Period, segLength, DFTLength, gaborK)
    [height, width]= size(img);
    img_gabor = zeros(width, height);
    segNum_h = ceil(height / segLength);
    segNum_w = ceil(width / segLength);
    for index_h = 1:segNum_h
        for index_w = 1:segNum_w
            if ROI(index_h, index_w) == 0
                continue
            end
            % Seg Image into Parts
            wStart = max(1, (index_w-1) * segLength + 1 - (DFTLength / 4));
            wEnd = min(width, (index_w-1) * segLength - (DFTLength / 4) + DFTLength);
            hStart = max(1, (index_h-1) * segLength + 1 - (DFTLength / 4));
            hEnd = min(height, (index_h-1) * segLength - (DFTLength / 4) + DFTLength);
            segImg = img(hStart:hEnd, wStart:wEnd);
            segImg = adapthisteq(segImg);
            segAngle = 90 + Angle(index_h, index_w);
            segPeriod = max(2, gaborK * Period(index_h, index_w));
            [rho, phi] = imgaborfilt(segImg, segPeriod, segAngle);
            segGabor = rho .* cos(phi);
            segGabor = Normalize(segGabor);
            img_gabor(hStart:hEnd, wStart:wEnd) = segGabor;
        end
    end
end

function [ROI, Angle, Period] = fingerDetector(img, segLength, DFTLength, fingerParam)
    [height, width] = size(img);
    segNum_h = ceil(height / segLength);
    segNum_w = ceil(width / segLength);
    ROI = zeros(segNum_h, segNum_w);
    Angle = zeros(segNum_h, segNum_w);
    Period = zeros(segNum_h, segNum_w);

    for index_h = 1:segNum_h
        for index_w = 1:segNum_w
            % Seg Image into Parts
            wStart = max(1, (index_w-1) * segLength + 1 - (DFTLength / 4));
            wEnd = min(width, (index_w-1) * segLength - (DFTLength / 4) + DFTLength);
            hStart = max(1, (index_h-1) * segLength + 1 - (DFTLength / 4));
            hEnd = min(height, (index_h-1) * segLength - (DFTLength / 4) + DFTLength);
            segImg = img(hStart:hEnd, wStart:wEnd);
            segImg = adapthisteq(segImg);
            %Apply DFT to Segmentated Image
            DFTImg = abs(fftshift(fft2(segImg)));
            DFTImg_sort = sort(DFTImg(:));
            if DFTImg_sort(end-1) < fingerParam  % No Fingerprint
                continue
            end
            % Get positions of the points
            [posX, posY] = find(DFTImg == DFTImg_sort(end - 1));
            %Invalid line elimination
            if length(posX) ~= 2
                continue
            end
            %Calculate distance and period
            distance = sqrt((posX(1) - posX(2))^2 + (posY(1) - posY(2))^2);
            Period(index_h, index_w) = 1 / distance;
            if distance == 2
                continue
            end
            ROI(index_h, index_w) = 1;
            %Calculate direction
            angle = atand((posY(1)-posY(2))/(posX(1)-posX(2)));
            Angle(index_h, index_w) = angle;
        end
    end
end

function obj = DrawDir(fig,dir,BLK_SIZE,LineSpec,ROI)
    linecolor = LineSpec(1);
    if length(LineSpec)>1
        linewidth = str2num(LineSpec(2));
    else
        linewidth = 1;
    end

    len = BLK_SIZE*0.8;

    figure(fig),hold on
    [h,w] = size(dir);
    obj = zeros(h,w);
    
    for row = 1:h
        for col = 1:w
            if (dir(row,col)>90 || dir(row,col)<-90) || (nargin>4 && ROI(row,col)==0)
                obj(row,col) = -1;
                continue
            end

            cx = (col-1)*BLK_SIZE+BLK_SIZE/2;
            cy = (row-1)*BLK_SIZE+BLK_SIZE/2;
            if 1
                linex(1) = cos(dir(row,col)*pi/180)*len/2;
                linex(2) = -cos(dir(row,col)*pi/180)*len/2;
                liney(1) = -sin(dir(row,col)*pi/180)*len/2;
                liney(2) = sin(dir(row,col)*pi/180)*len/2;
            else
                if dir(row,col)==90
                    linex(1) = 0;
                    liney(1) = -len/2;
                    linex(2) = 0;
                    liney(2) = len/2;
                elseif dir(row,col)<=45 && dir(row,col)>=-45
                    linex(1) = -len/2;
                    liney(1) = -linex(1)*tan(dir(row,col)*pi/180);
                    linex(2) = len/2;
                    liney(2) = -linex(2)*tan(dir(row,col)*pi/180);
                else
                    liney(1) = -len/2;
                    linex(1) = -liney(1)/tan(dir(row,col)*pi/180);
                    liney(2) = len/2;
                    linex(2) = -liney(2)/tan(dir(row,col)*pi/180);
                end

                linex(1) = cut(linex(1),-len/2,len/2);
                liney(1) = cut(liney(1),-len/2,len/2);
                linex(2) = cut(linex(2),-len/2,len/2);
                liney(2) = cut(liney(2),-len/2,len/2);
            end

            linex = linex+cx;
            liney = liney+cy;
            obj(row,col) = line(linex,liney,'color',linecolor,'linewidth',linewidth);
        end
    end
end

function y = cut(x,minval,maxval)
    y=x;
    if y<minval
        y=minval;
    end
    if y>maxval
        y=maxval;
    end
end

function results = Normalize(Image)
    maxNum = max(max(Image));
    minNum = min(min(Image));
    results = (Image - minNum) / (maxNum - minNum);
end