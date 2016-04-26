#!/usr/bin/env jruby

# Run as
# jruby -J-Xss65536k ./db_to_docs/search_text_to_doc.rb

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

user_searches = {}

puts "Getting searches ..."
Search.where(locale: 'US').order(id: :desc).limit(1000).pluck(:user_id, :quick_or_advance, :search_params_all).each_with_index do |search_row, i| # where('created_at >= ? AND created_at <= ?', 4.weeks.ago, Time.now)
  # puts "Search Row #{i} [#{search_row}]"
  (user_id, quick_or_advance, search_params_all) = search_row
  search_text = nil
  if quick_or_advance == 'advanced'
    search_params_hash = Rison.load(search_params_all['rison_params'])
    search_params_hash.each do |k, v|
      if k == :search_text || k =~ /^local_.+_input$/
        search_text = v.to_s
      end
    end
    search_params_hash = nil
  else
    search_text = search_params_all['search_text']
  end

  if search_text
    # puts "search_text: #{search_text}"
    if user_searches[user_id]
      user_searches[user_id] << search_text
    else
      user_searches[user_id] = [search_text]
    end
  end

end

user_searches.each_with_index do |(k, v), i|
  puts "#{i}, #{k}, #{v}"
  File.open("/root/mounts/mahout-examples/search-text-docs/#{i}_#{k}.txt", "w") do |f| # Overwrites file
    v.each {|t| f.puts t}
  end
end
