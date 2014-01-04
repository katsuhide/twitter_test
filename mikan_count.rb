# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'
require 'json'

## read the configuration method
def read_configuration
	config = YAML.load_file("config.yml")
	config_p = config["production"]
	return config_p
end

## read the configuration
config_p = read_configuration

## create the twitter client
tw = Twitter::Client.new(
	 consumer_key: config_p["consumer_key"],
	 consumer_secret: config_p["consumer_secret"],
	 oauth_token: config_p["oauth_token"],
	 oauth_token_secret: config_p["oauth_token_secret"]
)

## search tweets method
def search_tweets(tw, config_p, keyword)
	# TODO : since_idは前回値を引き継ぐようにする
	tweets  = tw.search(keyword, :count => config_p['fetch_size'], :result_type => "recent", :since_id => '0').results.reverse.map
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

## count tweets
def count_tweets(keyword, tweets)
	count = tweets.size
	tweets_number = [keyword, count]
	return tweets_number
end

## output the tweets number to the text file
def output_tweets_number(config_p, tweets_number)
	open(config_p['output_file_name'], "w") do |io|
		io.write(tweets_number)
		io.write("\n")
	end
end

## get the keyword list
# TODO : keywordとsince_idのセットでとってくるようにする
# TODO : 改行を読み込んでしまっている
f = open(config_p['keyword_list_file_name'])
keywords = f.readlines()

## loop each keywords
keywords.each{|keyword|
	## search tweets
	tweets = search_tweets(tw, config_p, keyword)

	## count tweets
	tweets_number = count_tweets(keyword, tweets);

	## output result
	puts tweets_number
	output_tweets_number(config_p, tweets_number)

}



puts 'end'
