# -*- encoding: utf-8 -*-
require 'twitter'
require 'yaml'

## 設定の読み込み
config = YAML.load_file("config.yml")
config_p = config["production"]

tw = Twitter::Client.new(
  consumer_key: config_p["consumer_key"],
  consumer_secret: config_p["consumer_secret"],
  oauth_token: config_p["oauth_token"],
  oauth_token_secret: config_p["oauth_token_secret"]
)

## データの検索
since_id = 0
counter = 0
keyword = "PASSPO"

tw.search(keyword, :count => 10, :result_type => "recent", :since_id => since_id).results.reverse.map do |status|
	# Tweet ID, ユーザ名、Tweet本文、投稿日を1件づつ表示
	puts status.id
	puts status.created_at
	puts "@" + status.from_user
	puts status.text
	print("\n")
	# 取得したTweet idをsince_idに格納
	# ※古いものから新しい順(Tweet IDの昇順)に表示されるため、
 	#  最終的に、取得した結果の内の最新のTweet IDが格納され、
	#  次はこのID以降のTweetが取得される
	since_id=status.id
      end
