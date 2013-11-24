# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'
require 'json'

## 設定の読み込み
config = YAML.load_file("config.yml")
config_p = config["production"]

tw = Twitter::Client.new(
  consumer_key: config_p["consumer_key"],
  consumer_secret: config_p["consumer_secret"],
  oauth_token: config_p["oauth_token"],
  oauth_token_secret: config_p["oauth_token_secret"]
)

## search tweets
def search_tweet(tw, keyword, since_id, fetch_size)
	result_map  = tw.search(keyword, :count => fetch_size, :result_type => "recent", :since_id => since_id).results.reverse.map
      return result_map
end

## print result of the search tweets
def print_tweets(result_map)
	result_map.each{ |result|
		# result  => hash
		h = Hash::new
		h.store("id", result.id)
		h.store("time", result.created_at)
		h.store("user", "@" + result.from_user)
		h.store("text", result.text)
		# hash => json
		j = JSON.pretty_generate(h)
		# j = JSON.generate(h)
		#  json => text file
		open("tweet.json", "a") do |io|
			JSON.dump(j, io)
		end
	}
end

## データの検索
since_id = 0
fetch_size = 1
f = open("anime_list.txt")
keywords = f.readlines()
# keywords = ["PASSPO", "AKB48"]
keywords.each{ |keyword|
	result_map = search_tweet(tw, keyword, since_id, fetch_size)
	print_tweets(result_map)
}
