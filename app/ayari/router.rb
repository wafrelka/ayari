require 'uri'
require 'sinatra/base'


module Ayari

	class Router < Sinatra::Base

		get /(.*)/ do |raw_req_path|

			req_path = URI.decode(raw_req_path)

			content_type :text
			"It works!\nRequest Path = #{req_path}"

		end

	end

end
