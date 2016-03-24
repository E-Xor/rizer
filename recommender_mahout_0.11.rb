#!/usr/bin/env jruby

puts "REQUIRES"

# Java
include Java

# Mahout
# MAHOUT_DIR should be pointed to /root/ml/apache-mahout-distribution-0.11.1
MAHOUT_DIR = ENV["MAHOUT_DIR"]
require "#{MAHOUT_DIR}/mahout-hdfs-0.11.1.jar"
require "#{MAHOUT_DIR}/mahout-mr-0.11.1.jar"
require "#{MAHOUT_DIR}/mahout-integration-0.11.1.jar"
require "#{MAHOUT_DIR}/mahout-math-0.11.1.jar"
Dir.glob("#{MAHOUT_DIR}/lib/*.jar").each { |d| require d }

# For FileDataModel
java_import org.apache.mahout.cf.taste.impl.model.file.FileDataModel

# For Recommender
java_import org.apache.mahout.cf.taste.eval.RecommenderBuilder
java_import org.apache.mahout.cf.taste.impl.similarity.PearsonCorrelationSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.EuclideanDistanceSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.SpearmanCorrelationSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.LogLikelihoodSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.TanimotoCoefficientSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.PearsonCorrelationSimilarity

java_import org.apache.mahout.cf.taste.impl.neighborhood.NearestNUserNeighborhood
java_import org.apache.mahout.cf.taste.impl.neighborhood.ThresholdUserNeighborhood

java_import org.apache.mahout.cf.taste.impl.recommender.GenericUserBasedRecommender
java_import org.apache.mahout.cf.taste.impl.recommender.GenericItemBasedRecommender

java_import org.apache.mahout.cf.taste.common.Weighting





puts "START"

data_model = FileDataModel.new(java.io.File.new('recommender_data.csv'))
puts "data_model: #{data_model.inspect}"

puts "Recommend for user"
similarity = PearsonCorrelationSimilarity.new(data_model)
puts "Similarity: #{similarity.inspect}"
neighborhood_size = 3.0
neighborhood = NearestNUserNeighborhood.new(Integer(neighborhood_size), similarity, data_model)
puts "Neighborhood: #{neighborhood.inspect}"
recommender = GenericUserBasedRecommender.new(data_model, neighborhood, similarity)
puts "Recommender: #{recommender.inspect}"

puts "RECOMMEND"

puts recommender.recommend(2, 3, nil) # Recoomend to user 2. Number of recommendations - 3

puts "ITEMS"

similarity = PearsonCorrelationSimilarity.new(data_model)
puts "Similarity: #{similarity.inspect}"
recommender = GenericItemBasedRecommender.new(data_model, similarity)
puts "Recommender: #{recommender.inspect}"

puts "SIMILLAR ITEMS"

puts recommender.mostSimilarItems(14, 3, nil) # Items simillar to item 14. Return 3 items


