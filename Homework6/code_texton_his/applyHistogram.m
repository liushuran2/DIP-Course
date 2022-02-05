function samples_hist = applyHistogram(samples_cluster)
% apply histogram for each image in the sample
% input is the sample
% output is the histogram result
N = size(samples_cluster, 3);
maxNumber = max(max(max(samples_cluster)));
samples_hist = zeros(N, maxNumber);
for i = 1:N
   for j = 1:maxNumber
       samples_hist(i, j) = sum(sum(samples_cluster(:, :, i) == j));
   end
end
end