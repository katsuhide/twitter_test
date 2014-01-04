# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'
require 'json'

## read the configuration for oauth
def read_configuration
	config = YAML.load_file("config.yml")
	config_p = config["production"]
	return config_p
end

## search tweets method
def search_tweet(tw, keyword, since_id, fetch_size)
	result_map  = tw.search(keyword, :count => fetch_size, :result_type => "recent", :since_id => since_id).results.reverse.map
      return result_map
end

## print result of the search tweets method
def print_tweets(result_map)
	result_map.each{ |result|
		## result  => hash
		h = Hash::new
		h.store("id", result.id)
		h.store("time", result.created_at)
		h.store("user", "@" + result.from_user)
		# h.store("text", result.text)
		config_p = read_configuration
		open(config_p['output_file_name'], "w") do |io|
			io.write(h.values)
			io.write("\n")
		end
	}
end

## create the twiter client
config_p = read_configuration
tw = Twitter::Client.new(
	 consumer_key: config_p["consumer_key"],
	 consumer_secret: config_p["consumer_secret"],
	 oauth_token: config_p["oauth_token"],
	 oauth_token_secret: config_p["oauth_token_secret"]
)

## execute to search tweet
since_id = 0
fetch_size = config_p['fetch_size']
hoge = config_p['keyword_list_file_name']
puts hoge
f = open(config_p['keyword_list_file_name'])
keywords = f.readlines()
# keywords = ["PASSPO", "AKB48"]
keywords.each{ |keyword|
	result_map = search_tweet(tw, keyword, since_id, fetch_size)
	print_tweets(result_map)
}
