#!/usr/bin/env jruby

puts "REQUIRES"

include Java

require 'yaml'
MAHOUT_DIR = ENV["MAHOUT_DIR"] # MAHOUT_DIR should be pointed to /root/ml/apache-mahout-distribution-0.11.1
require "#{MAHOUT_DIR}/mahout-hdfs-0.11.1.jar"
require "#{MAHOUT_DIR}/mahout-mr-0.11.1.jar"
require "#{MAHOUT_DIR}/mahout-integration-0.11.1.jar"
require "#{MAHOUT_DIR}/mahout-math-0.11.1.jar"
Dir.glob("#{MAHOUT_DIR}/lib/*.jar").each { |d| require d }

puts "IMPORTS"
# For FileDataModel
java_import org.apache.mahout.cf.taste.impl.model.file.FileDataModel

# For Recommender
java_import org.apache.mahout.cf.taste.eval.RecommenderBuilder
java_import org.apache.mahout.cf.taste.impl.similarity.PearsonCorrelationSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.EuclideanDistanceSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.SpearmanCorrelationSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.LogLikelihoodSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.TanimotoCoefficientSimilarity # Ignores rating column
java_import org.apache.mahout.cf.taste.impl.similarity.GenericItemSimilarity

java_import org.apache.mahout.cf.taste.impl.neighborhood.NearestNUserNeighborhood
java_import org.apache.mahout.cf.taste.impl.neighborhood.ThresholdUserNeighborhood

java_import org.apache.mahout.cf.taste.impl.recommender.GenericUserBasedRecommender
java_import org.apache.mahout.cf.taste.impl.recommender.GenericItemBasedRecommender

java_import org.apache.mahout.cf.taste.common.Weighting

# java_import org.apache.logging.log4j
# require "/usr/share/java/log4j-1.2.jar"

# log4j.rootLogger=INFO, stdout
# log4j.appender.stdout=org.apache.log4j.ConsoleAppender
# log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
# log4j.appender.stdout.layout.ConversionPattern="%d [%t] %-5p %c - %m%n"

puts "MySQL"
java_import org.apache.mahout.cf.taste.impl.model.jdbc.MySQLJDBCDataModel
java_import org.apache.mahout.cf.taste.impl.model.jdbc.ReloadFromJDBCDataModel
# apt-get install libmysql-java mysql-client -y
# CLASSPATH=$CLASSPATH:/usr/share/java/
# export CLASSPATH
java_import com.mysql.jdbc.jdbc2.optional.MysqlDataSource

db_config = YAML::load(IO.read('config/database.yml'))
data_source = MysqlDataSource.new()
data_source.setUser(db_config['username'])
data_source.setPassword(db_config['password'])
data_source.setServerName(db_config['host'])
data_source.setPortNumber(db_config['port'])
data_source.setDatabaseName(db_config['database'])

# CREATE VIEW v_recommender_data_source AS
# SELECT user_id, profile_id AS item_id, COUNT(*) AS rating, created_at FROM profile_views
# WHERE user_id IS NOT NULL AND profile_id > 0
# GROUP BY CONCAT(user_id, '_', profile_id) ORDER BY rating DESC

# CREATE TABLE t_recommender_data_source AS
# SELECT user_id, profile_id AS item_id, COUNT(*) AS rating FROM profile_views
# WHERE user_id IS NOT NULL AND profile_id > 0
# GROUP BY CONCAT(user_id, '_', profile_id) ORDER BY rating DESC;
data_model = ReloadFromJDBCDataModel.new(MySQLJDBCDataModel.new(data_source, "t_recommender_data_source", "user_id", "item_id", "rating", nil))
# ReloadFromJDBCDataModel

# data_model = FileDataModel.new(java.io.File.new(File.expand_path(File.dirname(__FILE__)) + '/audit_dev_for_rec.csv'))


puts "SIMILLAR ITEMS"
similarity = PearsonCorrelationSimilarity.new(data_model)
recommender = GenericItemBasedRecommender.new(data_model, similarity)
puts "Refresh..."
recommender.refresh(nil);
puts recommender.mostSimilarItems(1602, 3, nil) # Items simillar to item <FIRST ARG>. Return <SECOND ARG> items
# 2:49PM

# similarity = PearsonCorrelationSimilarity.new(data_model)
similarity = TanimotoCoefficientSimilarity.new(data_model)
neighborhood = NearestNUserNeighborhood.new(10, similarity, data_model) # <FIRST ARG> is nearest N users to a given user.
recommender = GenericUserBasedRecommender.new(data_model, neighborhood, similarity)

puts "Refresh..."
recommender.refresh(nil);

puts "RECOMMEND"

puts "Recommend 1. #{Time.now}"
puts recommender.recommend(46117, 3, nil) # Recoomend to user <FIRST ARG>. Number of recommendations - <SECOND ARG>
puts "Recommend 2. #{Time.now}"
puts recommender.recommend(23221, 3, nil) # Recoomend to user <FIRST ARG>. Number of recommendations - <SECOND ARG>
puts "Recommend 3. #{Time.now}"
puts recommender.recommend(59210, 3, nil) # Recoomend to user <FIRST ARG>. Number of recommendations - <SECOND ARG>
puts "Recommend 4. #{Time.now}"
puts recommender.recommend(191814, 3, nil) # Recoomend to user <FIRST ARG>. Number of recommendations - <SECOND ARG>



# Load array from DB via AR or something
# Check dates in current algorythms and query same periods
# Figure out rating
# Run different algorythms for the same user, uniq results
# Log user and number of recommendations given
# Join profile names to test


