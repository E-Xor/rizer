#!/usr/bin/env ruby

recommender = JrubyMahout::Recommender.new(
    "PearsonCorrelationSimilarity",
    5,
    "GenericUserBasedRecommender",
    false)

# recommender.data_model = JrubyMahout::DataModel.new(
#    "file",
#     { :file_path => "data.csv" }).data_model
# Your data will have to be in the following format:
#
# 1,3,5
# 1,2,1
# 2,3,5

puts recommender.recommend(2, 10, nil)

