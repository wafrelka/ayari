module Ayari

	module Dropbox

		module Hasher

			BLOCK_COUNT = 512
			READ_CHUNK_SIZE = 8192

			def self.compute_hash(path)

				full_hasher = Digest::SHA256.new
				block_hasher = Digest::SHA256.new
				buffer = String.new
				eof = false

				File.open(path) do |fp|

					while !eof

						block_hasher.reset

						BLOCK_COUNT.times do
							eof = fp.read(READ_CHUNK_SIZE, buffer).nil?
							break if eof
							block_hasher << buffer
						end

						full_hasher << block_hasher.digest

					end

				end

				full_hasher.hexdigest

			end

		end

	end

end
