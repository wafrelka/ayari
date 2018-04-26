$:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), '..', 'app'))
require 'logger'
require 'ayari'


if __FILE__ == $0

	token = ENV['AYARI_TOKEN']
	token_file = ENV['AYARI_TOKEN_FILE_PATH']
	storage_path = ENV['AYARI_STORAGE_PATH'] || 'data'

	if token.nil? && token_file.nil?
		puts "Dropbox token not provided."
		puts "Set AYARI_TOKEN or AYARI_TOKEN_FILE_PATH env variable."
		exit 1
	end

	if token.nil?
		token = File.binread(token_file).strip
	end

	storage = Ayari::LocalStorage.new(storage_path)

	logger = Logger.new(STDOUT)
	logger.level = Logger::INFO

	sync = Ayari::Dropbox::Synchronizer.new(token, storage, logger)

	sync.synchronize

end
