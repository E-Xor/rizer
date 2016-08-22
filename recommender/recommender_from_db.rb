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
STDOUT.sync = true

puts "Drops"
benchmark_start = Time.now
ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender__')
ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_media_brand')
ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_media_company')
ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_media_agency')
ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_agency_brand')
ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_agency_company')
ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS v_recommender_agency_agency')
puts(Time.now - benchmark_start)

def v_recomender_sql(client_type: :media, profile_type: :brand, days_ago: 30)
  case profile_type
  when :company
    join_table         = 'imp_company'
    join_id            = 'company_id'
    where_profile_type = 'Company'
  when :brand
    join_table         = 'imp_company_brand'
    join_id            = 'brand_id'
    where_profile_type = 'Brand'
  when :agency
    join_table         = 'imp_agency'
    join_id            = 'agency_id'
    where_profile_type = 'Agency'
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
    CREATE VIEW audit_dev.v_recommender_#{client_type}_#{profile_type} AS
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

puts(Time.now - benchmark_start)

puts "Pure"
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: nil,     profile_type: nil,      days_ago: 0))
puts(Time.now - benchmark_start)

puts "Media. Company."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :media,  profile_type: :company, days_ago: 0))
puts(Time.now - benchmark_start)

puts "Media. Brand."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :media,  profile_type: :brand,   days_ago: 0))
puts(Time.now - benchmark_start)

puts "Media. Agency."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :media,  profile_type: :agency,  days_ago: 0))
puts(Time.now - benchmark_start)

puts "Agency. Company."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :agency, profile_type: :company, days_ago: 0))
puts(Time.now - benchmark_start)

puts "Agency. Brand."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :agency, profile_type: :brand,   days_ago: 0))
puts(Time.now - benchmark_start)

puts "Agency. Agency."
ActiveRecord::Base.connection.execute(v_recomender_sql(client_type: :agency, profile_type: :agency,  days_ago: 0))
puts(Time.now - benchmark_start)


# ActiveRecord::Base.connection.execute('
  # CREATE VIEW v_recommender_data_source AS
  # SELECT user_id, profile_id, COUNT(*) AS rating FROM profile_views
  # WHERE user_id IS NOT NULL AND profile_id > 0
  # GROUP BY CONCAT(user_id, '_', profile_id) ORDER BY rating DESC;
# ')
# Company separately
# CREATE VIEW audit_dev.v_recommender_company AS
# SELECT user_id, profile_id, COUNT(*) AS rating FROM audit_dev.profile_views p
# INNER JOIN tlo_dev.imp_company c ON (c.company_id=p.profile_id)
# WHERE user_id IS NOT NULL AND profile_id > 0
# GROUP BY CONCAT(user_id, '_', profile_id) ORDER BY rating DESC;

data_model = ReloadFromJDBCDataModel.new(MySQLJDBCDataModel.new(data_source, "v_recommender_media_company", "user_id", "profile_id", "rating", nil))

puts "SIMILLAR ITEMS"
similarity = PearsonCorrelationSimilarity.new(data_model)
recommender = GenericItemBasedRecommender.new(data_model, similarity)
similarItems = recommender.mostSimilarItems(1602, 10, nil) # Items simillar to item <FIRST ARG>. Return <SECOND ARG> items
similarItems.each{|s| print "#{s.getItemID},"}; puts;

abort

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

# Test
# SELECT company_name,description FROM tlo_dev.imp_company WHERE company_id IN (8959,19944,6891,10524,643,3587,14955,3867,11833,4851);

# SELECT DISTINCT(description), COUNT(*) c FROM tlo_dev.imp_company c
# INNER JOIN audit_dev.profile_views p ON (c.company_id=p.profile_id)
# WHERE p.user_id=191814 GROUP BY description ORDER BY c DESC;
