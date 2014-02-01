# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'
require 'logger'

class TwitterUtil
	## 	initialize
	def initialize(log = nil)
		read_configuration
		create_client(get_available_client())
		@logger = log
		if @logger.nil? then
			@logger = Logger.new(STDOUT)
			@logger.level = Logger::INFO
		end
		@logger.debug("Twitter Util initialize")
	end

	## 	read the configuration method
	def read_configuration
		@config = YAML.load_file("config.yml")
		return @config
	end

	## 	get next index of twitter client
	def get_next_client_index(in_use_index)
		current_index = in_use_index.nil? ? -1: in_use_index
		oauth = @config['oauth']
		client_num = oauth.count
		return current_index < (client_num - 1) ? current_index + 1 : current_index + 1 - client_num
	end

	## 	get available client
	def get_available_client()
		@in_use_index = get_next_client_index(@in_use_index)
		return @config['oauth'][@in_use_index]
	end

	## 	create the twitter client
	def create_client(oauth)
		@client = Twitter::Client.new(
			 consumer_key: oauth["consumer_key"],
			 consumer_secret: oauth["consumer_secret"],
			 oauth_token: oauth["oauth_token"],
			 oauth_token_secret: oauth["oauth_token_secret"]
		)
	end

	## 	change twitter client
	def change_client
		create_client(get_available_client())
	end

	## 	print tweet
	def print_tweet(tweet)
		if !tweet.nil? then
			h = Hash::new
			h.store("id", tweet.id)
			h.store("time", tweet.created_at)
			h.store("user", "@" + tweet.from_user)
			h.store("text", tweet.text)
			@logger.debug(p h)
		end
	end

	## 	print result of the search tweets method
	def print_tweets(tweets)
		tweets.each{ |tweet|
			print_tweet(tweet)
		}
	end

	## 	get twitter client
	def get_client
		return @client
	end

	##  	search latest tweet
	def search_tweet(keyword)
		tweet =  @client.search(keyword, :count => 1, :result_type => "recent").results.reverse.map.first
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
	def search_tweets(fetch_size, keyword, since_id)
		tweets = @client.search(keyword, :count => fetch_size, :result_type => "recent", :since_id => since_id).results.reverse.map
		print_tweets(tweets)
		return  tweets
	end

	## 	search tweets method by since_id and max_id
	def search_tweets_by_both(fetch_size, keyword, since_id, max_id)
		tweets =  @client.search(keyword, :count => fetch_size, :result_type => "recent", :since_id => since_id, :max_id => max_id).results.reverse.map
		print_tweets(tweets)
		return  tweets
	end

end
