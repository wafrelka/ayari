require 'open-uri'
require 'tempfile'
require 'rspec_helper'
require 'ayari/dropbox_hash'


describe Ayari::DropboxHash do

	SAMPLE_URI = 'https://www.dropbox.com/static/images/developers/milky-way-nasa.jpg'
	SAMPLE_HASH = '485291fa0ee50c016982abbfa943957bcd231aae0492ccbaa22c58e3997b35e0'

	it 'computes the file hash correctly', internet_required: true do

		Tempfile.open("ayari-rspec-") do |tmp_fp|

			open(SAMPLE_URI) do |uri_fp|
				tmp_fp.write(uri_fp.read)
			end

			tmp_fp.sync
			path = tmp_fp.path

			expect(Ayari::DropboxHash.compute_hash(path)).to eq SAMPLE_HASH

		end

	end

end
