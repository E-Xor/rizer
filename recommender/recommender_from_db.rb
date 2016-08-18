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
# setLogWriter?

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
data_source.setLogWriter(nil)

# require 'yaml'
# require 'active_record'
# require 'bundler/setup'
# require 'rison'

# puts "Connecting to DB..."
# db_config = YAML::load(IO.read('config/database.yml'))
# ActiveRecord::Base.establish_connection(db_config)

# ActiveRecord::Base.connection.execute('
#   DROP VIEW v_recommender_data_source;
# ')
# ActiveRecord::Base.connection.execute('
#   CREATE VIEW v_recommender_data_source AS
#   SELECT user_id, profile_id, COUNT(*) AS rating FROM profile_views
#   WHERE user_id IS NOT NULL AND profile_id > 0
#   GROUP BY CONCAT(user_id, '_', profile_id) ORDER BY rating DESC;
# ')

data_model = ReloadFromJDBCDataModel.new(MySQLJDBCDataModel.new(data_source, "v_recommender_data_source", "user_id", "profile_id", "rating", nil))

puts "SIMILLAR ITEMS"
similarity = PearsonCorrelationSimilarity.new(data_model)
recommender = GenericItemBasedRecommender.new(data_model, similarity)
similarItems = recommender.mostSimilarItems(1602, 10, nil) # Items simillar to item <FIRST ARG>. Return <SECOND ARG> items
similarItems.each{|s| print "#{s.getItemID},"}; puts;

similarity = PearsonCorrelationSimilarity.new(data_model)
# similarity = TanimotoCoefficientSimilarity.new(data_model)
neighborhood = NearestNUserNeighborhood.new(20, similarity, data_model) # <FIRST ARG> is nearest N users to a given user.
recommender = GenericUserBasedRecommender.new(data_model, neighborhood, similarity)

puts "RECOMMEND"

# puts recommender.recommend(46117, 10, nil) # Recoomend to user <FIRST ARG>. Number of recommendations - <SECOND ARG>
recommender.recommend(46117, 10, nil).each{|s| print "#{s.getItemID},"}; puts;
recommender.recommend(23221, 10, nil).each{|s| print "#{s.getItemID},"}; puts;
recommender.recommend(59210, 10, nil).each{|s| print "#{s.getItemID},"}; puts;
recommender.recommend(191814, 10, nil).each{|s| print "#{s.getItemID},"}; puts;

# 1 month
# separately company, brand, agency_id
# Load array from DB via AR or something
# Check dates in current algorythms and query same periods
# Figure out rating
# Run different algorythms for the same user, uniq results
# Log user and number of recommendations given
# Join profile names to test

# SELECT v.*, c.company_name, a.agency_name, b.companybrand_name
# FROM `v_recommender_data_source` v
# LEFT JOIN tlo_dev.imp_company c ON (v.profile_id = c.company_id)
# LEFT JOIN tlo_dev.imp_company_brand b ON (v.profile_id = b.brand_id)
# LEFT JOIN tlo_dev.imp_agency a ON (v.profile_id = a.agency_id)
# WHERE v.user_id=59210;

# SELECT company_name FROM tlo_dev.imp_company WHERE company_id IN (57437,22979,13085,296559,26261,6891,12513,16641,67209)
# UNION
# SELECT companybrand_name FROM tlo_dev.imp_company_brand WHERE brand_id IN (57437,22979,13085,296559,26261,6891,12513,16641,67209)
# UNION
# SELECT agency_name FROM tlo_dev.imp_agency WHERE agency_id IN (57437,22979,13085,296559,26261,6891,12513,16641,67209);

