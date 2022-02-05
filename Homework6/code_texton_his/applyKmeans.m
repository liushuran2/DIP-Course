function [samples_cluster,centers] = applyKmeans(samples_res,k)
% apply kmeans algorithm to cluster all pixels into k classes.
% input are the samples responses and class numbers 
% output are the samples cluster result and kmeans centers
% personnally I recommand function 'kmeans', you can learn how 
% to use it by 'doc kmeans' or 'help kmeans'
samples_res = permute(samples_res, [3, 4, 1, 2]); % H, W, 5, 8
[H, W, N, fb] = size(samples_res);
kmeans_matrix = reshape(samples_res, [], fb); % H*W*5, 8
[samples_cluster, centers] = kmeans(kmeans_matrix, k, 'MaxIter', 1000, 'display', 'iter');
% [samples_cluster, centers] = kmeans(kmeans_matrix, k, 'display', 'iter');
samples_cluster = reshape(samples_cluster, H, W, N); % H*W, 5
end