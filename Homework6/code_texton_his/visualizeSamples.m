function visualizeSamples(samples_cluster, train_samples)
% visualize the samples result
[~, ~, N] = size(samples_cluster);
figure(1);
for i = 1:N
    subplot(2, N, i);
    imshow(train_samples.image{i});
    train_cluster = squeeze(samples_cluster(:, :, i));
    train_cluster = labeloverlay(train_samples.image{i}, train_cluster);
    subplot(2, N, i + N);
    imshow(train_cluster);
end
end