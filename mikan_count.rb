# -*- encoding: utf-8 -*-
require 'json'

open("tweet.json") do |io|
	puts JSON.load(io)
end
