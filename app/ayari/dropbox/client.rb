require 'json'
require 'faraday'
require 'faraday_middleware'


module Ayari

	module Dropbox

		FolderMetadata = Struct.new(:remote_path)
		FileMetadata = Struct.new(:remote_path, :rev, :hash)
		DeletedMetadata = Struct.new(:remote_path)

		class InvalidResponseError < StandardError; end
		class NetworkError < StandardError; end

		class Client

			DROPBOX_HOST_PART = {
				api: 'https://api.dropboxapi.com',
				content: 'https://content.dropboxapi.com',
				notify: 'https://notify.dropboxapi.com',
			}
			GARBAGE_COLLECTION_THRESHOLD_IN_BYTE = 1000000
			GARBAGE_COLLECTION_ENABLED = true

			def initialize(access_token, storage, logger)

				@access_token = access_token
				@storage = storage
				@logger = logger

				@api_conn = Faraday.new DROPBOX_HOST_PART[:api] do |conn|
					conn.authorization 'Bearer', access_token
					conn.request :json
					conn.response :json
					conn.adapter :net_http
				end

				@content_conn = Faraday.new DROPBOX_HOST_PART[:content] do |conn|
					conn.authorization 'Bearer', access_token
					conn.adapter :net_http
				end

				@notify_conn = Faraday.new DROPBOX_HOST_PART[:notify] do |conn|
					conn.request :json
					conn.response :json
					conn.adapter :net_http
				end

			end

			def wait_for_changes(cursor)

				begin

					res = @notify_conn.post '/2/files/list_folder/longpoll', { cursor: cursor, }

				rescue Faraday::ConnectionFailed, Faraday::TimeoutError
					raise NetworkError.new
				rescue Faraday::ParsingError => e
					raise InvalidResponseError.new("Invalid JSON: #{e}")
				end

				data = res.body
				changes = data.dig('changes')
				backoff = data.dig('backoff')

				if ! backoff.is_a?(Integer)
					backoff = 1
				end

				if ! (changes.is_a?(TrueClass) || changes.is_a?(FalseClass))
					raise InvalidResponseError.new("Invalid `changes`: #{data}")
				end

				[changes, backoff]

			end

			def retrieve_events(cursor)

				begin

					res = if cursor.nil?
						@api_conn.post '/2/files/list_folder', { path: '', recursive: true, }
					else
						@api_conn.post '/2/files/list_folder/continue', { cursor: cursor, }
					end

				rescue Faraday::ConnectionFailed, Faraday::TimeoutError
					raise NetworkError.new
				rescue Faraday::ParsingError => e
					raise InvalidResponseError.new("Invalid JSON: #{e}")
				end

				data = res.body
				cursor = data.dig('cursor')
				entries = data.dig('entries')

				if ! cursor.is_a?(String)
					raise InvalidResponseError.new("Invalid `cursor`: #{data}")
				end

				if ! entries.is_a?(Array)
					raise InvalidResponseError.new("Invalid `entries`: #{data}")
				end

				events = entries.map{ |e| self.class.parse_entry(e) }

				if events.any? { |e| e.nil? }
					raise InvalidResponseError.new("Invalid element in `entries`: #{data}")
				end

				[events, cursor]

			end

			def process_file_event(metadata)

				obj = @storage.get_object_info(metadata.remote_path)

				if obj&.hash == metadata.hash
					return false
				end

				begin
					new_file_path = @storage.create_untracked_file
					download_file(metadata, new_file_path)
					@storage.register_object(new_file_path, metadata.remote_path)
				rescue Ayari::FileNotFoundError
					retry
				end

				@storage.deregister_objects(metadata.remote_path)

				true

			end

			def process_folder_event(metadata)

				@storage.deregister_single_object(metadata.remote_path)

			end

			def process_delete_event(metadata)

				@storage.deregister_single_object(metadata.remote_path)
				@storage.deregister_objects(metadata.remote_path)

			end

			def process_event(metadata)

				case metadata
				when FileMetadata
					process_file_event(metadata)
				when FolderMetadata
					process_folder_event(metadata)
				when DeletedMetadata
					process_delete_event(metadata)
				end

			end

			def download_file(file_metadata, path)

				remote_path = file_metadata.remote_path
				@logger&.debug("Download started: '#{remote_path}' -> '#{path}'")

				File.open(path, 'w') do |fp|

					rev = file_metadata.rev
					prev_size = 0

					begin

						@content_conn.get '/2/files/download', { arg: { path: "rev:#{rev}" }.to_json } do |req|
							req.options.on_data = Proc.new do |chunk, overall_received_bytes|
								fp.write(chunk)
								if prev_size + GARBAGE_COLLECTION_THRESHOLD_IN_BYTE < overall_received_bytes
									prev_size = overall_received_bytes
									GC.start(full_mark: false) if GARBAGE_COLLECTION_ENABLED
								end
							end
						end

					rescue Faraday::ConnectionFailed, Faraday::TimeoutError
						raise NetworkError.new
					ensure
						GC.start(full_mark: false) if GARBAGE_COLLECTION_ENABLED
					end

				end

				@logger&.debug("Download finished: '#{remote_path}'")

			end

			def self.parse_entry(entry)

				return nil if ! entry.is_a?(Hash)

				tag = entry.dig('.tag')
				path_lower = entry.dig('path_lower')
				rev = entry.dig('rev')
				content_hash = entry.dig('content_hash')

				# normalize path_lower
				if path_lower.is_a?(String)
					path_lower.downcase!
					if ! path_lower.start_with?('/')
						path_lower = '/' + path_lower
					end
				end

				case tag
				when 'file'
					return nil if ! path_lower.is_a?(String)
					return nil if ! rev.is_a?(String)
					return nil if ! content_hash.is_a?(String)
					FileMetadata.new(path_lower, rev, content_hash)
				when 'folder'
					return nil if ! path_lower.is_a?(String)
					FolderMetadata.new(path_lower)
				when 'deleted'
					return nil if ! path_lower.is_a?(String)
					DeletedMetadata.new(path_lower)
				else
					nil
				end

			end

		end

	end

end
