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
			prefix = ENV['AYARI_PREFIX'] || ''

			set :storage, LocalStorage.new(storage_path)
			set :hidden_pattern, /^_/
			set :prefix, prefix

		end

		helpers do

			def path_to(path)
				RoutingRules.get_remote_path(path, @rendering_path)
			end

			def get_content(remote_path, locals={})

				obj = settings.storage.get_object_info(remote_path)
				return nil if obj.nil?

				begin
					txt = File.read(obj.local_path, encoding: ENCODING)
				rescue Errno::NOENT
					return nil
				end

				txt

			end

			def render_content(ty, remote_path, locals={})

				content = get_content(remote_path, locals)
				raise Sinatra::NotFound if content.nil?

				case ty
				when :md

					template_path, opts = Ayari::Markdown::Processor::process_text(content)
					template_remote_path = RoutingRules.get_remote_path(template_path, remote_path)
					render_content(:haml, template_remote_path, opts.merge(locals))

				when :haml

					@rendering_path = remote_path
					haml content, locals: locals

				when :erb

					@rendering_path = remote_path
					erb content, locals: locals, trim: '-'

				else

					raise Sinatra::NotFound

				end

			end

		end

		not_found do
			'404 Not Found'
		end

		get /(.*)/ do |raw_req_path|

			raise Sinatra::NotFound if ! raw_req_path.start_with?('/')

			req_path = settings.prefix + URI.decode(raw_req_path)
			candidates = RoutingRules.get_candidates(req_path)
			candidates = candidates.reject{ |path| path.split('/').any?{ |frag| settings.hidden_pattern.match?(frag) } }

			selected = candidates
				.lazy
				.map{ |c| [settings.storage.get_object_info(c), File.basename(c)] }
				.find{ |obj, fname| ! obj.nil? }

			raise Sinatra::NotFound if selected.nil?

			obj, fname = selected
			ext = File.extname(fname)

			case ext
			when '.md'
				render_content(:md, obj.remote_path)
			when '.haml'
				render_content(:haml, obj.remote_path)
			when '.erb'
				actual_fname = File.basename(fname, ".erb")
				types = MIME::Types.type_for(actual_fname)
				content_type types[0].to_s if ! types.empty?
				render_content(:erb, obj.remote_path)
			else
				types = MIME::Types.type_for(fname)
				content_type types[0].to_s if ! types.empty?
				send_file File.absolute_path(obj.local_path)
			end

		end

	end

end
