require 'ayari/dropbox/client'


module Ayari

	module Dropbox

		class Synchronizer

			def initialize(access_token, storage, logger)

				@client = Client.new(access_token, storage, logger)
				@storage = storage
				@logger = logger

			end

			def self.prettify_cursor(cursor)
				len = 13
				return "-" * len if ! cursor.is_a?(String)
				justed = cursor.rjust(len, ' ')
				cut = justed[0...(len - 3)] + "..."
				cut
			end

			def get_events(cursor)

				cursor_str = self.class.prettify_cursor(cursor)
				@logger&.info("Retrieving events... (cursor: #{cursor_str})")

				events = []

				begin
					has_more = true
					while has_more
						new_events, new_cursor, has_more = @client.retrieve_events(cursor)
						cursor = new_cursor
						events.concat(new_events)
					end
				rescue NetworkError => e
					@logger&.error("Network error: #{e}")
					return [[], nil]
				rescue InvalidResponseError => e
					@logger&.error("Invalid response: #{e}")
					return [[], nil]
				end

				[events, cursor]

			end

			def initialize_storage(events)

				listed = events.select{|ev| ev.is_a?(FileMetadata)}.map{|ev| ev.remote_path}
				all = @storage.get_all_object_info_list().map{|obj| obj.remote_path}
				not_listed = all - listed

				not_listed.each do |remote_path|
					@storage.deregister_single_object(remote_path)
					@logger&.info("Removed: '#{remote_path}'")
				end

			end

			def process_events(events)

				events.each do |ev|

					case ev
					when FileMetadata
						@logger&.debug("FileMetadata: '#{ev.remote_path}' (rev: #{ev.rev})")
					when FolderMetadata
						@logger&.debug("FolderMetadata: '#{ev.remote_path}'")
					when DeletedMetadata
						@logger&.debug("DeletedMetadata: '#{ev.remote_path}'")
					end

					begin
						result = @client.process_event(ev)
					rescue NetworkError => e
						@logger&.error("Network error: #{e}")
						return false
					end

					# show file addition and deletion
					case ev
					when FileMetadata
						if result
							@logger&.info("Saved  : '#{ev.remote_path}' (rev: #{ev.rev})")
						end
					when DeletedMetadata
						@logger&.info("Deleted: '#{ev.remote_path}'")
					end

				end

				true

			end

			def wait_for_changes(cursor)

				@logger&.info("Waiting changes...")

				loop do

					begin
						changed, backoff = @client.wait_for_changes(cursor)
					rescue NetworkError => e
						@logger&.error("Network error: #{e}")
						return false
					rescue InvalidResponseError => e
						@logger&.error("Invalid response: #{e}")
						return false
					end

					break if changed

					# default backoff set by #wait_for_changes is 1 second
					if backoff > 1
						@logger&.info("Backoff: #{backoff}")
					end

					sleep backoff

				end

				true

			end

			def synchronize()

				cursor = nil

				loop do

					initial = cursor.nil?
					events, new_cursor = get_events(cursor)
					cursor = new_cursor

					if cursor.nil?
						next
					end

					if initial
						initialize_storage(events)
					end

					if ! process_events(events)
						cursor = nil
						next
					end

					@logger&.info("Sweeping untracked files...")
					@storage.sweep_untracked_files()

					if ! wait_for_changes(cursor)
						cursor = nil
						next
					end

				end

			end

		end

	end

end
