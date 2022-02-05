function test_samples_labels = predictLabels(test_samples_hist,train_samples_hist)
% predict the labels of each image in the test sample according to the
% train sample histograms
% inputs are the test sample histograms and train sample histograms
% output is the label prediction result of the test samples
% personally I recommend function 'pdist2', you can learn more about the
% function by 'doc pdist2' or 'doc pdist2'
test_samples_labels.classId = zeros([25,1]);
distance = pdist2(test_samples_hist, train_samples_hist);
[~, class] = min(distance, [], 2);
test_samples_labels.classId = reshape(class, [], 1);
end