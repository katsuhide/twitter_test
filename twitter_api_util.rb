# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'

class TwitterUtil
	## 	initialize
	def initialize()
		config = read_configuration
		@tw = create_twitter_client(config)
	end

	## 	read the configuration method
	def read_configuration
		configs = YAML.load_file("config.yml")
		config = configs["production"]
		return config
	end

	## 	create the twitter client
	def create_twitter_client(config)
		tw = Twitter::Client.new(
			 consumer_key: config["consumer_key"],
			 consumer_secret: config["consumer_secret"],
			 oauth_token: config["oauth_token"],
			 oauth_token_secret: config["oauth_token_secret"]
		)
		return tw
	end

	##  	search latest tweet
	def search_tweet(keyword)
		return @tw.search(keyword, :count => 1, :result_type => "recent").results.reverse.map.first
	end

	## 	search tweets method
	def search_tweets(tw, count, keyword, since_id)
		return  @tw.search(keyword, :count => count, :result_type => "recent", :since_id => since_id).results.reverse.map
	end

	## 	search tweets method by since_id and max_id
	def search_tweets_by_both(tw, count, keyword, since_id, max_id)
		return @tw.search(keyword, :count => count, :result_type => "recent", :since_id => since_id, :max_id => max_id).results.reverse.map
	end


end
