require 'securerandom'
require 'fileutils'
require 'sequel'
require 'ayari/dropbox/hasher'


module Ayari

	ObjectInfo = Struct.new(:remote_path, :local_path, :hash)
	class FileNotFoundError < ArgumentError; end

	class LocalStorage

		SQLITE_DATABASE_FILENAME = 'objects.db'

		def initialize(base_path)

			@base_path = File.absolute_path(base_path)
			FileUtils.mkdir_p(@base_path)

			@db = Sequel.sqlite(File.join(@base_path, SQLITE_DATABASE_FILENAME))

			@db.create_table?(:objects) do
				string :remote_path, primary_key: true
				string :local_name, null: false
				string :hash, null: false
			end

			@table = @db[:objects]

		end

		def register_object(local_path, remote_path)

			local_name = File.basename(local_path)
			path = File.join(@base_path, local_name)

			if File.absolute_path(path) != File.absolute_path(local_path)
				raise ArgumentError.new("unmanagable local path: #{local_path}")
			end

			if ! remote_path.start_with?('/')
				raise ArgumentError.new("remote path should be prefixed with a slash: #{remote_path}")
			end

			if remote_path.end_with?('/')
				raise ArgumentError.new("remote path should not be suffixed with a slash: #{remote_path}")
			end

			@db.transaction(mode: :immediate) do

				# acquired the RESERVED lock
				# no removal occurs within the transaction
				# see the comment of #sweep_untracked_files

				if ! File.file?(path)
					raise FileNotFoundError.new(path)
				end

				hash = Dropbox::Hasher.compute_hash(path)

				@table.insert_conflict(:replace).insert(
					remote_path: remote_path,
					local_name: local_name,
					hash: hash,
				)

			end

		end

		def deregister_single_object(remote_path)

			@table.where(remote_path: remote_path).delete

		end

		def deregister_objects(remote_path_prefix)

			escaped_prefix = self.class.escape_for_sql_like_query(remote_path_prefix)

			normalized_prefix = escaped_prefix
			if ! normalized_prefix.end_with?('/')
				normalized_prefix += '/'
			end

			@table.where(Sequel.like(:remote_path, "#{normalized_prefix}%")).delete

		end

		def get_object_info(remote_path)

			obj = @table.where(remote_path: remote_path).first

			if obj.nil?
				nil
			else
				ObjectInfo.new(
					obj[:remote_path],
					File.join(@base_path, obj[:local_name]),
					obj[:hash],
				)
			end

		end

		def create_untracked_file()

			path = generate_random_file_path()

			while File.exist?(path)
				path = generate_random_file_path()
			end

			FileUtils.touch(path)
			path

		end

		def sweep_untracked_files()

			@db.transaction(mode: :immediate) do

				# acquired the RESERVED lock
				# no registration occurs within the transaction
				# see the comment of #register_object

				all_entries = Dir.entries(@base_path)
				all_files = all_entries.select{ |s| File.file?(s) }
				all_names = all_entries.map { |s| File.basename(s) }

				reserved = [SQLITE_DATABASE_FILENAME, '.', '..']
				registered = @table.all.map{ |e| e[:local_name] }

				untracked = all_names - reserved - registered

				untracked.each do |name|

					path = File.join(@base_path, name)
					FileUtils.rm(path)

				end

			end

		end

		def self.escape_for_sql_like_query(text)

			text.gsub('\\'){ '\\\\' }.gsub('%'){ '\\%' }

		end

		def generate_random_file_path()

			uuid = SecureRandom.uuid
			File.join(@base_path, "#{uuid}.bin")

		end

	end

end
