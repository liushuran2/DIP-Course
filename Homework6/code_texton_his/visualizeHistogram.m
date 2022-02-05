function visualizeHistogram(samples_hist)
% visualize histogram result of the samples
[N, ~] = size(samples_hist);
figure(2);
for i = 1:N
   subplot(1, N, i);
   bar(samples_hist(i, :));
end
end