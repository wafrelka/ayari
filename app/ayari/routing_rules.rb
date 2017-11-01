module Ayari

	module RoutingRules

		CANDIDATES_FOR_FILE = [
			'*',
			'*.md',
			'*.haml',
			'*.html',
			'*.txt',
		]

		CANDIDATES_FOR_DIR = [
			'*/index.md',
			'*/index.haml',
			'*/index.html',
		]

		def self.get_candidates(original_path)

			original_path_slashed = original_path
			if ! original_path_slashed.end_with?('/')
				original_path_slashed += '/'
			end

			c_file = CANDIDATES_FOR_FILE.map{|c| c.gsub('*', original_path)}
			c_dir = CANDIDATES_FOR_DIR.map{|c| c.gsub('*/', original_path_slashed)}
			is_file = ! original_path.end_with?('/')

			if is_file
				c_file + c_dir
			else
				c_dir
			end

		end

	end

end