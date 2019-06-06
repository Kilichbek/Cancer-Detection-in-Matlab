function a = get_accuracy(predicted_labels,ground_truth)

accuracy = sum(predicted_labels == ground_truth) / numel(ground_truth);
a = 100 * accuracy;

end 