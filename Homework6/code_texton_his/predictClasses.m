function test_samples_cluster = predictClasses(test_samples_res,centers)
% predict the class of each pixel for all images responses in the sample according to
% the kmeans centers.
% inputs are the images responses sample and kmeans centers
% output is the cluster result of the sample
% personnally I recommend function 'pdist2', you can learn how to use it
% by 'doc pdist2' or 'help pdist2'
[N, fb, H, W] = size(test_samples_res);
test_samples_cluster = zeros(H, W, N);
test_samples_res = permute(test_samples_res, [1, 3, 4, 2]); % 25, H, W, 8
for image = 1:N
    sample = squeeze(test_samples_res(image, :, :, :));
    sample = reshape(sample, [], fb);
    dist = pdist2(sample, centers);
    [~, class] = min(dist, [], 2);
    class = reshape(class, H, W);
    test_samples_cluster(:, :, image) = class;
end
end