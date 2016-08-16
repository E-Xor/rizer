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
java_import org.apache.mahout.cf.taste.impl.similarity.TanimotoCoefficientSimilarity

java_import org.apache.mahout.cf.taste.impl.neighborhood.NearestNUserNeighborhood
java_import org.apache.mahout.cf.taste.impl.neighborhood.ThresholdUserNeighborhood

java_import org.apache.mahout.cf.taste.impl.recommender.GenericUserBasedRecommender
java_import org.apache.mahout.cf.taste.impl.recommender.GenericItemBasedRecommender

java_import org.apache.mahout.cf.taste.common.Weighting


# java_import org.apache.mahout.cf.taste.impl.model.jdbc.PostgreSQLJDBCDataModel
# java_import org.postgresql.ds.PGPoolingDataSource
# @data_model = PostgreSQLJDBCDataModel.new(@data_source, params[:table_name], "user_id", "item_id", "rating", "created")

# https://github.com/vasinov/jruby_mahout/blob/master/lib/jruby_mahout/postgres_manager.rb

# MysqlDataSource dataSource = new MysqlDataSource();
# dataSource.setServerName("my_database_host");
# dataSource.setUser("my_user");
# dataSource.setPassword("my_password");
# dataSource.setDatabaseName("my_database_name");

# JDBCDataModel dataModel = new MySQLJDBCDataModel(
#     dataSource, "my_prefs_table", "my_user_column",
#     "my_item_column", "my_pref_value_column", "my_timestamp_column");

# java_import org.apache.logging.log4j
# require "/usr/share/java/log4j-1.2.jar"

# log4j.rootLogger=INFO, stdout
# log4j.appender.stdout=org.apache.log4j.ConsoleAppender
# log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
# log4j.appender.stdout.layout.ConversionPattern="%d [%t] %-5p %c - %m%n"

puts "MySQL imports"
java_import org.apache.mahout.cf.taste.impl.model.jdbc.MySQLJDBCDataModel
# apt-get install libmysql-java -y
# CLASSPATH=$CLASSPATH:/usr/share/java/
# export CLASSPATH
java_import com.mysql.jdbc.jdbc2.optional.MysqlDataSource

puts "DB Config"
db_config = YAML::load(IO.read('config/database.yml'))
puts db_config.inspect
data_source = MysqlDataSource.new()
data_source.setUser(db_config['username'])
data_source.setPassword(db_config['password'])
data_source.setServerName(db_config['host'])
data_source.setPortNumber(db_config['port'])
data_source.setDatabaseName(db_config['database'])

puts "Execute"
# CREATE VIEW v_recommender_data_source AS
# SELECT user_id, profile_id AS item_id, COUNT(*) AS rating, created_at FROM profile_views
# WHERE user_id IS NOT NULL AND profile_id > 0
# GROUP BY CONCAT(user_id, '_', profile_id) ORDER BY rating DESC
data_model = MySQLJDBCDataModel.new(data_source, "v_recommender_data_source", "user_id", "item_id", "rating", "created_at")
puts data_model.inspect

similarity = PearsonCorrelationSimilarity.new(data_model)
puts "Similarity: #{similarity.inspect}"
neighborhood_size = 3.0
neighborhood = NearestNUserNeighborhood.new(Integer(neighborhood_size), similarity, data_model)
puts "Neighborhood: #{neighborhood.inspect}"
recommender = GenericUserBasedRecommender.new(data_model, neighborhood, similarity)
puts "Recommender: #{recommender.inspect}"

puts "RECOMMEND"

puts recommender.recommend(59537, 3, nil) # Recoomend to user 2. Number of recommendations - 3

puts "ITEMS"

similarity = PearsonCorrelationSimilarity.new(data_model)
puts "Similarity: #{similarity.inspect}"
recommender = GenericItemBasedRecommender.new(data_model, similarity)
puts "Recommender: #{recommender.inspect}"

puts "SIMILLAR ITEMS"

puts recommender.mostSimilarItems(11059, 3, nil) # Items simillar to item 14. Return 3 items

