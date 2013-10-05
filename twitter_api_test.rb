# -*- encoding: utf-8 -*-
require 'twitter'

tw = Twitter::Client.new(
  consumer_key: 'GhoK5Qq0NFkJSdYCjZRsNg',
  consumer_secret: 'DBBBtivnR37VEDqVnmm7GvZIjN6xFpfnX1uumb7vk',
  oauth_token: '982458823-0zibxIHw2T9xa3nTnelJf7uZnjEuCxWzarlSwFbK',
  oauth_token_secret: 'zkeDsGH8KNiYA5uPivKrxnhuPPGKM3u0xStolbbY'
)

# つぶやき
# tw.update("fuga");

# タイムラインの取得
timeline =tw.home_timeline(:count => 10)
timeline.each{ |line|
	puts line.text
}