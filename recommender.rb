include Java
$CLASSPATH << "jars/postgresql-9.4.1207.jre7.jar"

require 'jruby_mahout'

puts "START"

recommender = JrubyMahout::Recommender.new(
    "LogLikelihoodSimilarity",
    3,
    "GenericUserBasedRecommender",
    false)

recommender.data_model = JrubyMahout::DataModel.new(
   "file",
    { :file_path => "recommender_data.csv" }).data_model

puts "RECOMMEND"

puts recommender.recommend(4, 3, nil)

puts "EVALUATE"

puts recommender.evaluate(0.7, 0.3)

puts "SIMILLAR USERS"

puts recommender.similar_users(1, 5, nil)

puts "BECAUSE"

puts recommender.recommended_because(1, 138, 5)

puts "PREFERENCE"

puts recommender.estimate_preference(1, 138)

puts "END"