img = imread('106_3.bmp');
img = im2double(img);
segLength = 16;
DFTLength = 32;
fingerParam = 20;
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
%normalization period matrix
maxNum = max(max(Period));
minNum = min(min(Period));
Period = (Period - minNum) / (maxNum - minNum);
Period = imresize(Period, 16, 'nearest');
imwrite(Period, 'Period.png');
figure(1);
hold on;
imshow(img);
DrawDir(1, Angle, 16, 'r', ROI);

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
