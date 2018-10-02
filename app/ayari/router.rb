require 'uri'
require 'mime/types'
require 'sinatra/base'
require 'haml'
require 'ayari/local_storage'
require 'ayari/routing_rules'
require 'ayari/markdown'


module Ayari

	class Router < Sinatra::Base

		ENCODING = 'UTF-8'

		configure do

			storage_path = ENV['AYARI_STORAGE_PATH'] || 'data'

			set :storage, LocalStorage.new(storage_path)

		end

		helpers do

			def render_haml(remote_path, locals={})

				obj = settings.storage.get_object_info(remote_path)
				if obj.nil?
					raise Sinatra::NotFound
				end

				begin
					txt = File.read(obj.local_path, encoding: ENCODING)
				rescue Errno::NOENT
					raise Sinatra::NotFound
				end

				haml txt, locals: locals

			end

		end

		not_found do
			'404 Not Found'
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
			ext = File.extname(fname)

			case ext
			when '.md'

				begin
					txt = File.read(obj.local_path, encoding: ENCODING)
				rescue Errno::NOENT
					raise Sinatra::NotFound
				end

				template_rel_path, opts = Ayari::Markdown::Processor::process_text(txt)
				template_path = File.absolute_path(template_rel_path, File.dirname(obj.remote_path))
				render_haml(template_path, opts)

			when '.haml'

				render_haml(obj.remote_path)

			else

				types = MIME::Types.type_for(fname)

				if types.length > 0
					content_type types[0].to_s
				end

				send_file File.absolute_path(obj.local_path)

			end

		end

	end

end
