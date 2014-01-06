# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'
require 'csv'

## read the configuration method
def read_configuration
	configs = YAML.load_file("config.yml")
	config = configs["production"]
	return config
end

## read the configuration
config = read_configuration

## create the twitter client
tw = Twitter::Client.new(
	 consumer_key: config["consumer_key"],
	 consumer_secret: config["consumer_secret"],
	 oauth_token: config["oauth_token"],
	 oauth_token_secret: config["oauth_token_secret"]
)

## search tweets method
def search_tweets(tw, config, keyword, since_id)
	tweets  = tw.search(keyword, :count => config['fetch_size'], :result_type => "recent", :since_id => since_id).results.reverse.map
      return tweets
end

## print result of the search tweets method
def print_tweets(tweets)
	tweets.each{ |tweet|
		## tweet  => hash
		h = hash::new
		h.store("since_id", tweet.id)
		h.store("time", tweet.created_at)
		h.store("user", "@" + tweet.from_user)
		# h.store("text", tweet.text)
		puts h
	}
end

## get max since_id
def get_max_id(since_id, tweets)
	max_id = since_id
	tweets.each{|tweet|
		if tweet.id > max_id then
			max_id = tweet.id
		end
	}
	return max_id
end

## count tweets
def count_tweets(keyword, since_id, tweets)
	max_id = get_max_id(since_id, tweets)
	count = tweets.size
	result_tweets = [keyword, max_id, count]
	return result_tweets
end

## output the tweets number to the text file
def output_result_tweets(config, result_tweets)
	CSV.open(config['output_file_name'], "a") do |row|
		day = Time.now
		record = []
		record .push(day)
		record.push(result_tweets[0])
		record.push(result_tweets[1])
		record.push(result_tweets[2])
		row << record
	end
end

## update keyword list file
def update_keyword_list_file(config, new_keyword_list)
	CSV.open(config['keyword_list_file_name'],  "w") do |csv_row|
		new_keyword_list.each{|list_row|
			csv_row << list_row
		}
	end
end

## get the keyword list
keyword_list_file = CSV.table(config['keyword_list_file_name'])

## loop each keywords
new_keyword_list = [["keyword", "since_id"]]
keyword_list_file.each{|list|
	keyword = list[0]
	since_id = list[1]
	## search tweets
	tweets = search_tweets(tw, config, keyword, since_id)

	## count tweets
	result_tweets = count_tweets(keyword, since_id, tweets);

	## output result
	output_result_tweets(config, result_tweets)

	## add keyword & since_id to the new file
	new_keyword_list.push([keyword, result_tweets[1]])
}

## update keyword list file
update_keyword_list_file(config, new_keyword_list)
