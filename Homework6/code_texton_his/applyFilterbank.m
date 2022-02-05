function samples_res = applyFilterbank(train_samples,fb)
% apply Filter into the images of the sample,
% input is the images sample and filter bank
% output is the filter respons of the images sample
% replace it with your implementation

[H, W] = size(train_samples.image{1});
num = length(train_samples.image);
numfb = size(fb, 3);
samples_res = zeros(num, numfb, H, W);
for i = 1:num
    train_samples.image{i} = im2double(train_samples.image{i});
   for j = 1:numfb
        samples_res(i, j, :, :) = imfilter(train_samples.image{i}, fb(:, :, j));
   end
end
end