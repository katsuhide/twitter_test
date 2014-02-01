# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'
require 'csv'

## 	read the configuration method
def read_configuration
	return YAML.load_file("config.yml")
end

## 	construct result
def contruct_result(tweets)
	result = []
	tweets.each{|tweet|
		h = Hash::new
		h.store("id", tweet.id)
		h.store("time", tweet.created_at)
		result.push(h)
	}
      return result
end

## 	search tweets method
def search_tweets(tw, fetch_size, keyword, since_id)
	tweets  = tw.search(keyword, :count => fetch_size, :result_type => "recent", :since_id => since_id).results.reverse.map
      # return tweets.to_a
      return contruct_result(tweets)
end

## 	search tweets method by since_id and max_id
def search_tweets_by_both(tw, fetch_size, keyword, since_id, max_id)
	tweets  = tw.search(keyword, :count => fetch_size, :result_type => "recent", :since_id => since_id, :max_id => max_id).results.reverse.map
      return contruct_result(tweets)
end

## 	print result of the search tweets method
def print_tweets(tweets)
	tweets.each{ |tweet|
		p tweet
		# ## 	tweet  => hash
		# h = Hash::new
		# h.store("id", tweet.id)
		# h.store("time", tweet.created_at)
		# h.store("user", "@" + tweet.from_user)
		# # h.store("text", tweet.text)
		# puts h
	}
end

## output the tweets number to the text file
def output_result_tweets(config, keyword, since_id, latest_tweet, count)
	CSV.open(config['output_file_name'], "a") do |row|
		if !latest_tweet.nil? then
			day = Time.now
			record = []
			record .push(day)
			record.push(keyword)
			record.push(latest_tweet['id'])
			record.push(count)
			row << record
		end
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

## 	再帰検索
def repeat_back_search(tw, count, keyword, since_id, min_id, base_tweets)
	tweets = search_tweets_by_both(tw, count, keyword, since_id, min_id-1)
	min_id = get_min_id(tweets)
	base_tweets += tweets
	if tweets.count != 0 then
		puts "Count:" + tweets.size.to_s + ", Min_id: " + min_id.to_s + ", Max_id: " + get_max_id(tweets).to_s
		base_tweets = repeat_back_search(tw, count, keyword, since_id, min_id, base_tweets)
	end
	return base_tweets
end

## 	since_id以降のTweetを全件取得する
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

## 	Error handling when twitter api rate limit
def swith_twitter_account()
	puts "[TODO] Account Change"
end

# START
## 	read the configuration
config = read_configuration
count = config["fetch_size"]

## 	create the twitter client
tw = Twitter::Client.new(
	 consumer_key: config["consumer_key"],
	 consumer_secret: config["consumer_secret"],
	 oauth_token: config["oauth_token"],
	 oauth_token_secret: config["oauth_token_secret"]
)

## 	get the keyword list
keyword_list_file = CSV.table(config['keyword_list_file_name'])

## 	loop each keywords
new_keyword_list = [["keyword", "since_id"]]
keyword_list_file.each{|list|
	keyword = list[0]
	since_id = list[1]
	tweets = nil

	## 	get all tweets by filtering
	begin
		tweets = search_all_tweets(tw, count, keyword, since_id).sort_by{|tweet| tweet['id']}

		## 	create output data	<= [keyword, max_id, count]
		result_tweets = [keyword, tweets[tweets.size-1], tweets.size]
		puts result_tweets

		## 	output result
		latest_tweet = tweets[tweets.size-1]
		output_result_tweets(config, keyword, since_id, latest_tweet, tweets.size)

	rescue Twitter::Error::TooManyRequests => tw_error
		puts "[ERROR]" + tw_error.to_s + " during searching " + keyword
		swith_twitter_account()
	end

	## 	add keyword & since_id to the new file
	if tweets.nil? || latest_tweet.nil? then
	 	new_since_id = since_id
	else
	 	new_since_id = latest_tweet['id']
	end
	new_keyword_list.push([keyword, new_since_id])
}

## 	update keyword list file
update_keyword_list_file(config, new_keyword_list)
