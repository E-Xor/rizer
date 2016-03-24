#!/usr/bin/env jruby

include Java
$CLASSPATH << "jars/postgresql-9.4.1207.jre7.jar"

require 'jruby_mahout' # MAHOUT_DIR was pointed to /root/ml/mahout-distribution-0.7

puts "START"

recommender = JrubyMahout::Recommender.new(
    "PearsonCorrelationSimilarity",
    3.0, # ThresholdUserNeighborhood, similarity should be greate than that value
    "GenericUserBasedRecommender",
    false)

data_model = JrubyMahout::DataModel.new(
   "file",
    { :file_path => "recommender_data.csv" }).data_model

recommender.data_model = data_model

puts "RECOMMEND"

puts recommender.recommend(2, 3, nil) # Recoomend to user 2. Number of recommendations - 3

puts "EVALUATE"

puts recommender.evaluate(0.5, 1.0)
# Training percentage and evaluation percentage.
# The former represents which part of your dataset should be used to “train” the recommender.
# The latter is used to evaluate the recommender.
# Mahout, basically, tries to guess how users would rate individual items in the evaluation
# part of the dataset and then gives the average difference between real and guessed
# preferences. The lower the difference is—the better. 0.0 is the perfect result,
# meaning that the recommender got all recommendations right. This pretty much never
# happens in reality. 1.0 or less for a five star rating system would be a decent result.

puts "SIMILLAR USERS"

puts recommender.similar_users(2, 3, nil) # Users simillar to user 2. Max number of users to find - 3

puts "PREFERENCE"

puts recommender.estimate_preference(2, 14) # User ID, Item ID
puts recommender.estimate_preference(2, 3) # User ID, Item ID
puts recommender.estimate_preference(2, 1) # User ID, Item ID


recommender = JrubyMahout::Recommender.new(
    "GenericItemSimilarity",
    3.0, # ThresholdUserNeighborhood, similarity should be greater than that value
    "GenericItemBasedRecommender",
    false)

recommender.data_model = data_model;

puts "SIMILLAR ITEMS"

puts recommender.similar_items(14, 3, nil) # Items simillar to item 14. Return 3 items

puts "BECAUSE"

puts recommender.recommended_because(2, 14, 3) # User ID -2, Item ID - 14, 3 - amount of influential items.

puts "END"
