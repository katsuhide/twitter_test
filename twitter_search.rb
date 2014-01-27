# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'
require 'json'

def read_configuration
	configs = YAML.load_file("config.yml")
	config = configs["production"]
	return config
end

def search_tweets(tw, fetch_size, keyword, since_id)
	tweets  = tw.search(keyword, :count => fetch_size, :result_type => "recent", :since_id => since_id).results.reverse.map
	result = []
	tweets.each{|tweet|
		h = Hash::new
		h.store("id", tweet.id)
		h.store("time", tweet.created_at)
		result.push(h)
	}
      # return tweets.to_a
      return result
end

def search_tweets_by_maxid(tw, fetch_size, keyword, max_id)
	tweets  = tw.search(keyword, :count => fetch_size, :result_type => "recent", :max_id => max_id).results.reverse.map
      return tweets.to_a
end

def search_tweets_by_both(tw, fetch_size, keyword, since_id, max_id)
	tweets  = tw.search(keyword, :count => fetch_size, :result_type => "recent", :since_id => since_id, :max_id => max_id).results.reverse.map
      return tweets.to_a
end

## 	print result of the search tweets method
# def print_tweets(tweets)
# 	tweets.each{ |tweet|
# 		## 	tweet  => hash
# 		h = Hash::new
# 		h.store("id", tweet.id)
# 		h.store("time", tweet.created_at)
# 		# h.store("user", "@" + tweet.from_user)
# 		# h.store("text", tweet.text)
# 		puts h['id']
# 	}
# end

def print_tweets(tweets)
	tweets.each{ |tweet|
		p tweet
	}
end

## 	get min id of the tweets
def get_min_id(tweets)
	ids = []
	tweets.each{|tweet|
		# ids.push(tweet.id)
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

## 	再帰検索
def repeat_back_search(tw, count, keyword, since_id, min_id, base_tweets)
	# puts "repeat Since_id: " + since_id.to_s + ",    Min_id : " + min_id.to_s
	tweets = search_tweets_by_both(tw, count, keyword, since_id, min_id-1)
	min_id = get_min_id(tweets)
	base_tweets += tweets
	puts "Count:" + tweets.size.to_s + ", Min_id: " + since_id.to_s + ", Max_id: " + get_max_id(tweets).to_s
	# puts "tweets.count = " + tweets.count.to_s
	if tweets.count != 0 then
		base_tweets = repeat_back_search(tw, count, keyword, since_id, min_id, base_tweets)
	end
	return base_tweets
end

def search_all_tweets(tw, count, keyword, since_id)
	## 直近のTweetを取得
	tweets = search_tweets(tw, count, keyword, since_id)
	puts "Count:" + tweets.size.to_s + ", Min_id: " + get_min_id(tweets).to_s + ", Max_id: " + get_max_id(tweets).to_s
	## そこから前回取得結果まで遡る
	if tweets.count != 0 then
		min_id = get_min_id(tweets)
		tweets = repeat_back_search(tw, count, keyword, since_id, min_id, tweets)
	end
	return tweets
end

# START
## 	read the configuration
config = read_configuration

## 	create the twitter client
tw = Twitter::Client.new(
	 consumer_key: config["consumer_key"],
	 consumer_secret: config["consumer_secret"],
	 oauth_token: config["oauth_token"],
	 oauth_token_secret: config["oauth_token_secret"]
)

keyword = ARGV[0]
since_id = ARGV[1]
flag = ARGV[2].to_i
count = 100
puts keyword
puts since_id

tweets = search_tweets(tw, count, keyword, since_id)
# print_tweets(tweets)
puts "Count:" + tweets.size.to_s + ", Min_id: " + get_min_id(tweets).to_s + ", Max_id: " + get_max_id(tweets).to_s

if flag == 0 then
	exit(0)
end
## get all tweets by filtering
# tweets = search_all_tweets(tw, count, keyword, since_id).sort_by{|tweet| tweet.id}
tweets = search_all_tweets(tw, count, keyword, since_id).sort_by{|tweet| tweet['id']}
# print_tweets(tweets)
result_tweets = [keyword, tweets[tweets.size-1]['id'], tweets.size]
p result_tweets
