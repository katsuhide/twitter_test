# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'
require 'csv'

## 	read the configuration method
# TODO : ここで認証がOauthアカウントが複数かえるようにする
def read_configuration
	configs = YAML.load_file("config.yml")
	config = configs["production"]
	return config
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

# ## 	get max since_id
# def get_max_id(since_id, tweets)
# 	max_id = since_id
# 	min_id = since_id
# 	tweets.each{|tweet|
# 		if tweet.id > max_id then
# 			max_id = tweet.id
# 		end
# 		if tweet.id < min_id then
# 			min_id = tweet.id
# 		end
# 	}
# 	p "max_id:" + max_id.to_s
# 	p "min_id:" + min_id.to_s
# 	return max_id
# end

# ## count tweets
# def count_tweets(keyword, since_id, tweets)
# 	max_id = get_max_id(since_id, tweets)
# 	count = tweets.size
# 	result_tweets = [keyword, max_id, count]
# 	return result_tweets
# end

## output the tweets number to the text file
def output_result_tweets(config, result_tweets)
	CSV.open(config['output_file_name'], "a") do |row|
		if !result_tweets[1].nil? then
			day = Time.now
			record = []
			record .push(day)
			record.push(result_tweets[0])
			record.push(result_tweets[1]['id'])
			record.push(result_tweets[2])
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

	# ## 	search tweets
	# tweets = search_tweets(tw, config['fetch_size'], keyword, since_id)

	## 	get all tweets by filtering
	tweets = search_all_tweets(tw, count, keyword, since_id).sort_by{|tweet| tweet['id']}

	## 	count tweets
	# result_tweets = count_tweets(keyword, since_id, tweets);

	## 	create output data	<= [keyword, max_id, count]
	result_tweets = [keyword, tweets[tweets.size-1], tweets.size]
	puts result_tweets

	## 	output result
	output_result_tweets(config, result_tweets)

	## 	add keyword & since_id to the new file
	if !result_tweets[1].nil?
		new_keyword_list.push([keyword, result_tweets[1]['id']])
	end
}

## 	update keyword list file
update_keyword_list_file(config, new_keyword_list)
