#!/usr/bin/env jruby

# In case I need models in files
# recursively requires all files in ./lib and down that end in .rb
# Dir.glob('./lib/*').each do |folder|
#   Dir.glob(folder +"/*.rb").each do |file|
#     require file
#   end
# end

# Tells AR what db file to use
require 'yaml'
require 'active_record'
require 'bundler/setup'
require 'rison'

puts "Connecting to DB..."
db_config = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection(db_config)

class Search < ActiveRecord::Base
  serialize :search_params_all, Hash

end

puts "Getting searches ..."
Search.where(quick_or_advance: 'advanced').order(id: :desc).limit(100).pluck(:search_params_all).each_with_index do |search_row, i| # where('created_at >= ? AND created_at <= ?', 4.weeks.ago, Time.now)
  puts "Search Row [#{search_row}]"
  search_row_hash = Rison.load(search_row['rison_params'])
  search_row_text = ''
  search_row_hash_size = search_row_hash.size
  search_row_hash.each_with_index do |(k, v), i|
    puts "Param [#{i}/#{search_row_hash_size}] Key [#{k}]"
    next if k =~ /^related_.+|^no_related_.+|^per_page$|^page$|^type$|^subtype$|_sort$|_inc$|_mult$/ # skip page numbers, counters, etc. Removed |^subtype$|, can be put back
    if v.is_a? Array
      v.each {|a|  search_row_text += "#{k}_#{a} "}
    elsif v.is_a? Hash
      # Nothing for now
      puts "Hash! #{v.to_json}"
    else
      search_row_text += "#{k}_#{v} "
    end
  end
  puts "search_row_text: #{search_row_text}"

  File.open("/root/mounts/mahout-examples/search-docs/#{i}.txt", "w") do |f| # Overwrites file
    f.puts search_row_text
  end
end
