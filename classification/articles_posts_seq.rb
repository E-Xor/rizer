#!/usr/bin/env jruby

puts "REQUIRES"

# Java
include Java

# Hadoop
java_import org.apache.hadoop.conf.Configuration;
java_import org.apache.hadoop.fs.FileSystem;
java_import org.apache.hadoop.fs.Path;
java_import org.apache.hadoop.io.SequenceFile;
java_import org.apache.hadoop.io.Text;

# AR
require 'yaml'
require 'active_record'
require 'bundler/setup'
require 'rison'



# import org.apache.hadoop.conf.Configuration;
# import org.apache.hadoop.fs.FileSystem;
# import org.apache.hadoop.fs.Path;
# import org.apache.hadoop.io.SequenceFile;
# import org.apache.hadoop.io.Text;


# Configuration conf = new Configuration();
# FileSystem fs = FileSystem.get(conf);

# Path outputPath = new Path("c:\\temp");

# Text key = new Text(); // Example, this can be another type of class
# Text value = new Text(); // Example, this can be another type of class

# SequenceFile.Writer writer = new SequenceFile.Writer(fs, conf, outputPath, key.getClass(), value.getClass());

# while(condition) {

#     key = Some text;
#     value = Some text;

#     writer.append(key, value);
# }

# writer.close();

puts "Connecting to DB..."
db_config = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection(db_config)

class DvArticles < ActiveRecord::Base
  serialize :search_params_all, Hash

end

# Get DvArticles
# Put in categories by common tag

# Get posts

