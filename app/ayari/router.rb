require 'uri'
require 'mime/types'
require 'sinatra/base'
require 'ayari/local_storage'
require 'ayari/routing_rules'


module Ayari

	class Router < Sinatra::Base

		configure do

			storage_path = ENV['AYARI_STORAGE_PATH'] || 'data'

			set :storage, LocalStorage.new(storage_path)

		end

		get /(.*)/ do |raw_req_path|

			storage = settings.storage

			req_path = URI.decode(raw_req_path)
			candidates = RoutingRules.get_candidates(req_path)

			selected = candidates
				.lazy
				.map{ |c| [storage.get_object_info(c), File.basename(c)] }
				.find{ |obj, fname| ! obj.nil? }

			if selected.nil?
				raise Sinatra::NotFound
			end

			obj, fname = selected

			types = MIME::Types.type_for(fname)

			if types.length > 0
				content_type types[0].to_s
			end

			send_file File.absolute_path(obj.local_path)

		end

	end

end
