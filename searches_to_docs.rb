#!/usr/bin/env jruby

# In case I need models in files
# recursively requires all files in ./lib and down that end in .rb
# Dir.glob('./lib/*').each do |folder|
#   Dir.glob(folder +"/*.rb").each do |file|
#     require file
#   end
# end

# Tells AR what db file to use
db = YAML::load(IO.read('../config/database.yml'))
ActiveRecord::Base.establish_connection(db_config)
