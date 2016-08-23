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
# java_import org.apache.mahout.cf.taste.impl.model.file.FileDataModel

# For Recommender
#java_import org.apache.mahout.cf.taste.eval.RecommenderBuilder

# Similarities http://archive-primary.cloudera.com/cdh4/cdh/4/mahout-0.7-cdh4.3.2/mahout-core/index.html?org/apache/mahout/cf/taste/impl/neighborhood/ThresholdUserNeighborhood.html
java_import org.apache.mahout.cf.taste.impl.similarity.PearsonCorrelationSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.EuclideanDistanceSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.SpearmanCorrelationSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.LogLikelihoodSimilarity
java_import org.apache.mahout.cf.taste.impl.similarity.TanimotoCoefficientSimilarity # Ignores rating column
# java_import org.apache.mahout.cf.taste.impl.similarity.GenericItemSimilarity

java_import org.apache.mahout.cf.taste.impl.neighborhood.NearestNUserNeighborhood
# java_import org.apache.mahout.cf.taste.impl.neighborhood.ThresholdUserNeighborhood # Too sensitive

java_import org.apache.mahout.cf.taste.impl.recommender.GenericUserBasedRecommender
java_import org.apache.mahout.cf.taste.impl.recommender.GenericItemBasedRecommender

java_import org.apache.mahout.cf.taste.common.Weighting

puts "MySQL"
java_import org.apache.mahout.cf.taste.impl.model.jdbc.MySQLJDBCDataModel
java_import org.apache.mahout.cf.taste.impl.model.jdbc.ReloadFromJDBCDataModel
# apt-get install libmysql-java mysql-client -y
# CLASSPATH=$CLASSPATH:/usr/share/java/
# export CLASSPATH
java_import com.mysql.jdbc.jdbc2.optional.MysqlDataSource

db_config = YAML::load(IO.read("#{File.expand_path(File.dirname(__FILE__))}/../config/database.yml"))

data_source = MysqlDataSource.new()
data_source.setUser(db_config['username'])
data_source.setPassword(db_config['password'])
data_source.setServerName(db_config['host'])
data_source.setPortNumber(db_config['port'])
data_source.setDatabaseName(db_config['database'])

require 'yaml'
require 'active_record'
require 'bundler/setup'
# require 'rison'

puts "Connecting to DB..."
# db_config = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection(db_config)

puts "Drops"
# ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender__;')
# ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_media_brand;')
# ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_media_company;')
# ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_media_agency;')
# ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_agency_brand;')
# ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_agency_company;')
# ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_agency_agency;')

def v_recomender_sql(client_type: :media, profile_type: :brand, days_ago: 30)
  case profile_type
  when :company
    join_table         = 'imp_company'
    join_id            = 'company_id'
    where_profile_type = 'company'
  when :brand
    join_table         = 'imp_company_brand'
    join_id            = 'brand_id'
    where_profile_type = 'brand'
  when :agency
    join_table         = 'imp_agency'
    join_id            = 'agency_id'
    where_profile_type = 'agency'
  end

  profile_type_subquery = ''
  if join_table && join_id
    profile_type_join_subquery = " INNER JOIN tlo_dev.#{join_table} jt ON (jt.#{join_id}=p.profile_id)"
    profile_type_where_subquery = " INNER JOIN tlo_dev.#{join_table} jt ON (jt.#{join_id}=p.profile_id)"
  end

  profile_type_where_subquery = ''
  if where_profile_type
    profile_type_where_subquery = " AND profile_type='#{where_profile_type}'"
  end

  client_type_subquery = ''
  case client_type
  when :media
    client_type_subquery = " AND user_id NOT IN (SELECT DISTINCT(user_id) FROM tlo_dev.fm_users INNER JOIN tlo_dev.fm_accounts USING(account_id) WHERE category='Agency')"
  when :agency
    client_type_subquery = " AND user_id     IN (SELECT DISTINCT(user_id) FROM tlo_dev.fm_users INNER JOIN tlo_dev.fm_accounts USING(account_id) WHERE category='Agency')"
  end

  since_time_subquery = ''
  if days_ago > 0
    start_time  = (Time.now - days_ago.days).to_s(:db)
    since_time_subquery = "AND p.created_at >= '#{start_time}'"
  end

  sql_string = "
    CREATE OR REPLACE VIEW audit_dev.v_recommender_#{client_type}_#{profile_type} AS
    SELECT user_id, profile_id, COUNT(*) AS rating FROM audit_dev.profile_views p
    #{profile_type_join_subquery}
    WHERE profile_id > 0 AND user_id IS NOT NULL #{profile_type_where_subquery}
    #{client_type_subquery}
    #{since_time_subquery}
    GROUP BY CONCAT(user_id, '_', profile_id) ORDER BY rating DESC;
  "
  puts sql_string

  return sql_string
end

puts "Media. Company."
#ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :media,  profile_type: :company, days_ago: 0))

data_model = ReloadFromJDBCDataModel.new(MySQLJDBCDataModel.new(data_source, "v_recommender_media_company", "user_id", "profile_id", "rating", nil))

similarity  = PearsonCorrelationSimilarity.new(data_model)
similarity  = EuclideanDistanceSimilarity.new(data_model)
similarity  = SpearmanCorrelationSimilarity.new(data_model)
similarity  = LogLikelihoodSimilarity.new(data_model)
similarity2 = TanimotoCoefficientSimilarity.new(data_model)
neighborhood  = NearestNUserNeighborhood.new(20, similarity, data_model) # <FIRST ARG> is nearest N users to a given user.
neighborhood2 = NearestNUserNeighborhood.new(20, similarity2, data_model) # <FIRST ARG> is nearest N users to a given user.
recommender =  GenericUserBasedRecommender.new(data_model, neighborhood, similarity)
recommender2 = GenericUserBasedRecommender.new(data_model, neighborhood2, similarity2)

# puts recommender.recommend(46117, 10, nil) # Recoomend to user <FIRST ARG>. Number of recommendations - <SECOND ARG>

# CREATE TABLE `recommend_profiles` (
#   `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
#   `user_id` int(11) NOT NULL,
#   `profile_id` int(11) NOT NULL,
#   `profile_type` enum('company','brand','agency') NOT NULL DEFAULT 'company',
#   `client_type` enum('media','agency') NOT NULL DEFAULT 'media',
#   `created_at` datetime NOT NULL,
#   PRIMARY KEY (`id`),
#   UNIQUE KEY `user_id_3` (`user_id`,`profile_id`,`profile_type`),
#   KEY `user_id` (`user_id`),
#   KEY `profile_type` (`profile_type`),
#   KEY `client_type` (`client_type`),
#   KEY `user_id_2` (`user_id`,`profile_type`)
# ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

puts "RECOMMEND"
ActiveRecord::Base.connection.execute('TRUNCATE recommend_profiles;')
users = ActiveRecord::Base.connection.select_all("SELECT DISTINCT(user_id) FROM v_recommender_media_company;").rows
puts "User count: #{users.count}\n"
no_rec_users = []
insert_sql = ''
users.each_with_index do |u, i|
begin
  print "\r#{i+1} / #{users.count}"

  recs  = recommender.recommend(u.first, 10, nil)
  recs2 = recommender2.recommend(u.first, 10, nil)
  insert_sql = "INSERT INTO recommend_profiles (user_id, profile_id, profile_type, client_type, created_at) VALUES\n"
  all_recs = recs.map(&:getItemID) + recs2.map(&:getItemID)
  if all_recs.count == 0
    # puts " 0 recommendations for #{u.first}"
    no_rec_users << u.first
    next
  end
  all_recs.uniq.each do |r|
    insert_sql += "(#{u.first}, #{r}, 'company', 'media', NOW()),\n"
  end
  insert_sql[insert_sql.length-2]='; '
  ActiveRecord::Base.connection.execute(insert_sql);
rescue => e
  puts
  raise e
end
end

# Default: 20 neigbours
# 1448 total
# 0 rec - 135 users
# SELECT user_id, COUNT(*) c FROM recommend_profiles GROUP BY user_id HAVING c < 20;
# 1-19 recs - 1173 users
# 1-10 recs - 103

# 5 neigbours - 450, 969
# 10 neigbours - 227, 1155
# 40 neighbours - 72, 1114

# 20 neigbours, Pearsons - 842, 606
# 20.neigbours, Tanimoto - 185, 1263
# 20.neigbours, Euclidean - 
# 20.neigbours, Spearman - 
# 20.neigbours, LogLikelihood - 

# Test relevancy
# SELECT r.user_id, r.profile_id, c.company_name, c.description, c.revenues, c.num_employees FROM recommend_profiles r LEFT JOIN tlo_dev.imp_company c ON (c.company_id=r.profile_id) WHERE user_id=198128
# UNION
# SELECT p.user_id, p.profile_id, c.company_name, c.description, c.revenues, c.num_employees FROM profile_views p LEFT JOIN tlo_dev.imp_company c ON (c.company_id=p.profile_id) WHERE profile_type='company' AND user_id=198128
# LIMIT 30;

# count users with no recommendations, change neighbours to 5 and 40 and compare
puts "\nUsers with no recommendations: #{no_rec_users.count}"
puts "\nUsers with no recommendations: #{no_rec_users.join(', ')}"

abort
puts "Media. Brand."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :media,  profile_type: :brand,   days_ago: 0))

puts "Media. Agency."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :media,  profile_type: :agency,  days_ago: 0))

puts "Agency. Company."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :agency, profile_type: :company, days_ago: 0))

puts "Agency. Brand."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :agency, profile_type: :brand,   days_ago: 0))

puts "Agency. Agency."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :agency, profile_type: :agency,  days_ago: 0))

data_model = ReloadFromJDBCDataModel.new(MySQLJDBCDataModel.new(data_source, "v_recommender_media_company", "user_id", "profile_id", "rating", nil))

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

# separately company, brand, agency_id
# separate user by pillar. example of TV for media and kids for agencies
# include follows?
# look at last 30 days
# Run different algorythms for the same user, uniq results
# Log user and number of recommendations given
# Join profile names to test
# Find business profiles based on contact views

# Test
# SELECT company_name,description FROM tlo_dev.imp_company WHERE company_id IN (8959,19944,6891,10524,643,3587,14955,3867,11833,4851);

# SELECT DISTINCT(description), COUNT(*) c FROM tlo_dev.imp_company c
# INNER JOIN audit_dev.profile_views p ON (c.company_id=p.profile_id)
# WHERE p.user_id=191814 GROUP BY description ORDER BY c DESC;
