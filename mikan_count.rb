# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'
require 'csv'
require './twitter_api_util.rb'

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
def search_tweets(keyword, since_id)
	tweets = @tw.search_tweets(@fetch_size, keyword, since_id)
	return contruct_result(tweets)
end

## 	search tweets method by since_id and max_id
def search_tweets_by_both(keyword, since_id, max_id)
	tweets  = @tw.search_tweets_by_both(@fetch_size, keyword, since_id, max_id)
      return contruct_result(tweets)
end

## output the tweets number to the text file
def output_result_tweets(keyword, since_id, latest_tweet, count)
	CSV.open(@config['output_file_name'], "a") do |row|
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
def update_keyword_list_file(new_keyword_list)
	CSV.open(@config['keyword_list_file_name'],  "w") do |csv_row|
		new_keyword_list.each{|list_row|
			csv_row << list_row
		}
	end
end

## 	再帰検索
def repeat_back_search(keyword, since_id, min_id, base_tweets)
	tweets = search_tweets_by_both(keyword, since_id, min_id-1)
	min_id = @tw.get_min_id(tweets)
	base_tweets += tweets
	if tweets.count != 0 then
		@logger.info("Count:" + tweets.size.to_s + ", Min_id: " + min_id.to_s + ", Max_id: " + @tw.get_max_id(tweets).to_s)
		base_tweets = repeat_back_search(keyword, since_id, min_id, base_tweets)
	end
	return base_tweets
end

## 	since_id以降のTweetを全件取得する
def search_all_tweets(keyword, since_id)
	## 直近のTweetを取得
	@logger.info("Start getting the latest tweets.")
	tweets = search_tweets(keyword, since_id)
	@logger.info("Count:" + tweets.size.to_s + ", Min_id: " + @tw.get_min_id(tweets).to_s + ", Max_id: " + @tw.get_max_id(tweets).to_s)

	## そこから前回取得結果まで遡る
	@logger.info("Start getting the other tweets")
	if tweets.count != 0 then
		min_id = @tw.get_min_id(tweets)
		tweets = repeat_back_search(keyword, since_id, min_id, tweets)
	end
	return tweets
end

## 	Error handling when twitter api rate limit
def swith_twitter_account()
	@tw.change_client
end

# START
@logger = Logger.new(File.basename(__FILE__, File.extname(__FILE__)).to_s + ".log" , 5)
@logger.level = Logger::INFO
@tw = TwitterUtil.new(@logger)
@config = read_configuration
@fetch_size = @config["fetch_size"]

## 	get the keyword list
keyword_list_file = CSV.table(@config['keyword_list_file_name'])

## 	loop each keywords
new_keyword_list = [["keyword", "since_id"]]
keyword_list_file.each{|list|
	keyword = list[0]
	since_id = list[1]
	tweets = nil

	## 	get all tweets by filtering
	begin
		@logger.info("START!!!" + "keyword: " + keyword + ", since_id: " + since_id.to_s)
		tweets = search_all_tweets(keyword, since_id).sort_by{|tweet| tweet['id']}

		## 	create output data	<= [keyword, max_id, fetch_size]
		result_tweets = [keyword, tweets[tweets.size-1], tweets.size]
		@logger.info(p result_tweets)

		## 	output result
		latest_tweet = tweets[tweets.size-1]
		output_result_tweets(keyword, since_id, latest_tweet, tweets.size)

	rescue Twitter::Error::TooManyRequests => tw_error
		@logger.error(tw_error.to_s + " during searching " + keyword)
		swith_twitter_account()
	rescue => ex
		@logger.error(ex)
	ensure
		@logger.info("END!!!" + "keyword: " + keyword + ", since_id: " + since_id.to_s)
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
update_keyword_list_file(new_keyword_list)