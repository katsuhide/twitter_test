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

# つぶやき
# tw.update("fuga");

# タイムラインの取得
timeline =tw.home_timeline(:count => 10)
timeline.each{ |line|
	puts line.text
}