# -*- encoding: utf-8 -*-
require './twitter_api_util.rb'
require 'yaml'
require 'csv'
require 'logger'

## 	read the configuration method
def read_configuration
	configs = YAML.load_file("config.yml")
	config = configs["production"]
	return config
end

## 	update keyword list file
def update_keyword_list_file(config, new_keyword_list)
	CSV.open(config['keyword_list_file_name'],  "w") do |csv_row|
		new_keyword_list.each{|list_row|
			csv_row << list_row
		}
	end
end

## 	add keyword list to file
def add_keyword_lsit_file(keyword)
	## 	get max id
	tweet = @util.search_tweet(keyword)
	since_id = tweet.nil? ? nil : tweet['id']

	CSV.open(@config['keyword_list_file_name'],  "a") do |csv_row|
		csv_row << [keyword, since_id]
	end
end

## 	update keyword list
def update_keyword_list
	## 	read the keyword list
	keyword_list_file = CSV.table(@config['keyword_list_file_name'])

	## 	update the keyword list
	new_keyword_list = [["keyword", "since_id"]]
	keyword_list_file.each{|list|
		keyword = list[0]
		since_id = list[1]

		tweet = @util.search_tweet(keyword)
		new_since_id = tweet.nil? ? since_id : tweet['id']
		new_keyword_list.push([keyword, new_since_id])
	}

	## 	update keyword list file
	update_keyword_list_file(@config, new_keyword_list)
end

## 	print keyword list file
def print_keywrod_list_file
	keyword_list_file = CSV.table(@config['keyword_list_file_name'])
	@logger.info("\r\n" + keyword_list_file.to_csv)
end

## initialize
@logger = Logger.new("update_keyword_list.log", 5)
@logger.level = Logger::DEBUG
@util = TwitterUtil.new(@logger)
@config = read_configuration
mode = ARGV[0]
new_keyword = ARGV[1]

if mode.to_i ==1 then
	## 	add new keyword to the keyword list file
	@logger.info("add new keyword to the keyword list file")
	add_keyword_lsit_file(new_keyword)
else
	## 	update keyword list
	@logger.info("update keyword list")
	update_keyword_list
end

print_keywrod_list_file
