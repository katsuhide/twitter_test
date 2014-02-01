# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'
require 'logger'

class TwitterUtil
	## 	initialize
	def initialize(log = nil)
		config = read_configuration
		create_client(config)
		@logger = log
		if @logger.nil? then
			@logger = Logger.new(STDOUT)
			@logger.level = Logger::INFO
		end
		@logger.debug("Twitter Util initialize")
	end

	## 	read the configuration method
	def read_configuration
		configs = YAML.load_file("config.yml")
		config = configs["production"]
		return config
	end

	## 	print tweet
	def print_tweet(tweet)
		@logger.debug(tweet)
		if !tweet.nil? then
			h = Hash::new
			h.store("id", tweet.id)
			h.store("time", tweet.created_at)
			h.store("user", "@" + tweet.from_user)
			h.store("text", tweet.text)
			@logger.info(p h)
		end
	end

	## 	print result of the search tweets method
	def print_tweets(tweets)
		tweets.each{ |tweet|
			print_tweet(tweet)
		}
	end

	## 	create the twitter client
	def create_client(config)
		@tw = Twitter::Client.new(
			 consumer_key: config["consumer_key"],
			 consumer_secret: config["consumer_secret"],
			 oauth_token: config["oauth_token"],
			 oauth_token_secret: config["oauth_token_secret"]
		)
	end

	## 	get twitter client
	def get_client
		return @tw
	end

	##  	search latest tweet
	def search_tweet(keyword)
		tweet =  @tw.search(keyword, :count => 1, :result_type => "recent").results.reverse.map.first
		print_tweet(tweet)
		return tweet
	end

	## 	get min id of the tweets
	def get_min_id(tweets)
		ids = []
		tweets.each{|tweet|
			ids.push(tweet['id'])
		}
		return ids.min
	end

	## 	get max id of the tweets
	def get_max_id(tweets)
		ids = []
		tweets.each{|tweet|
			ids.push(tweet['id'])
		}
		return ids.max
	end

	## 	search tweets method
	def search_tweets(count, keyword, since_id)
		tweets = @tw.search(keyword, :count => count, :result_type => "recent", :since_id => since_id).results.reverse.map
		print_tweets(tweets)
		return  tweets
	end

	## 	search tweets method by since_id and max_id
	def search_tweets_by_both(count, keyword, since_id, max_id)
		return @tw.search(keyword, :count => count, :result_type => "recent", :since_id => since_id, :max_id => max_id).results.reverse.map
	end

end
