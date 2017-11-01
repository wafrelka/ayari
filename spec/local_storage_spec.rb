require 'rspec_helper'
require 'ayari/local_storage'
require 'ayari/dropbox_hash'


describe Ayari::LocalStorage do

	let(:dir) { @dir }
	let(:storage) { Ayari::LocalStorage.new(dir) }

	around do |example|
		Dir.mktmpdir('ayari-rspec-') do |tmpdir|
			@dir = tmpdir
			example.run
		end
	end

	describe '#create_untracked_file' do

		it 'creates an untracked file under the base directory' do

			path = storage.create_untracked_file

			expect(File.file?(path)).to be true
			expect(File.dirname(path)).to eq_path dir

		end

		it 'creates unique files for each calls' do

			path_a = storage.create_untracked_file
			path_b = storage.create_untracked_file

			expect(path_a).not_to eq path_b

		end

	end

	describe '#register_object' do

		it 'registers the given file to the database' do

			path = storage.create_untracked_file
			File.binwrite(path, 'contents')

			storage.register_object(path, '/remote-name')
			info = storage.get_object_info('/remote-name')
			hash = Ayari::DropboxHash.compute_hash(path)

			expect(info&.remote_path).to eq '/remote-name'
			expect(info&.local_path).to eq_path path
			expect(info&.hash).to eq hash

		end

		it 'overwrites the database when the remote_name conflicts' do

			path_a = storage.create_untracked_file
			path_b = storage.create_untracked_file

			storage.register_object(path_a, '/remote-name')
			storage.register_object(path_b, '/remote-name')
			info = storage.get_object_info('/remote-name')

			expect(info&.local_path).to eq_path path_b

		end

		it 'stores the information of multiple objects' do

			path_a = storage.create_untracked_file
			path_b = storage.create_untracked_file

			storage.register_object(path_a, '/remote-name-a')
			storage.register_object(path_b, '/remote-name-b')
			info_a = storage.get_object_info('/remote-name-a')
			info_b = storage.get_object_info('/remote-name-b')

			expect(info_a&.local_path).to eq_path path_a
			expect(info_b&.local_path).to eq_path path_b

		end

		it 'forces `remote_name` to be prefixed with a slash' do

			path = storage.create_untracked_file
			expect{storage.register_object(path, 'wrong')}.to raise_error(ArgumentError)

		end

		it 'forces `remote_name` not to be suffixed with a slash' do

			path = storage.create_untracked_file
			expect{storage.register_object(path, '/wrong/')}.to raise_error(ArgumentError)

		end

	end

	describe '#deregister_single_object' do

		it 'removes an object from the database' do

			path = storage.create_untracked_file

			storage.register_object(path, '/remote-name')
			storage.deregister_single_object('/remote-name')
			info = storage.get_object_info('/remote-name')

			expect(info).to be nil

		end

		it 'does not remove the actual file when removing an object' do

			path = storage.create_untracked_file

			storage.register_object(path, '/remote-name')
			storage.deregister_single_object('/remote-name')

			expect(File.file?(path)).to be true

		end

		it 'cleans the database for re-registration' do

			path_a = storage.create_untracked_file
			path_b = storage.create_untracked_file

			storage.register_object(path_a, '/remote-name')
			storage.deregister_single_object('/remote-name')
			storage.register_object(path_b, '/remote-name')
			info = storage.get_object_info('/remote-name')

			expect(info&.local_path).to eq_path path_b

		end

		it 'does not remove unrelated objects' do

			path_a = storage.create_untracked_file
			path_b = storage.create_untracked_file

			storage.register_object(path_a, '/remote-name-a')
			storage.register_object(path_b, '/remote-name-b')
			storage.deregister_single_object('/remote-name-a')
			info_b = storage.get_object_info('/remote-name-b')

			expect(info_b&.local_path).to eq_path path_b

		end

		it 'does not raise an error when there is no object to remove' do

			expect{storage.deregister_single_object('/aaa')}.not_to raise_error

		end

	end

	describe '#deregister_objects' do

		it 'removes multiple objects whose prefix is the same as the specified one' do

			path = storage.create_untracked_file

			storage.register_object(path, '/aaa/xxx')
			storage.register_object(path, '/aaa/yyy')
			storage.register_object(path, '/aaa/zzz/www')

			storage.deregister_objects('/aaa/')

			expect(storage.get_object_info('/aaa/xxx')).to be nil
			expect(storage.get_object_info('/aaa/yyy')).to be nil
			expect(storage.get_object_info('/aaa/zzz/www')).to be nil

		end

		it 'complements the trailing slash of `remote_path_prefix`' do

			path = storage.create_untracked_file

			storage.register_object(path, '/aaa/xxx')
			storage.register_object(path, '/aaa/yyy')
			storage.register_object(path, '/aaa/zzz/www')

			storage.deregister_objects('/aaa')

			expect(storage.get_object_info('/aaa/xxx')).to be nil
			expect(storage.get_object_info('/aaa/yyy')).to be nil
			expect(storage.get_object_info('/aaa/zzz/www')).to be nil

		end

		it 'does not remove unrelated objects' do

			path = storage.create_untracked_file

			storage.register_object(path, '/aaa/bbb/xxx')
			storage.register_object(path, '/aaa/bbb')
			storage.register_object(path, '/aaa/ccc/xxx')

			storage.deregister_objects('/aaa/bbb')
			storage.deregister_objects('/aaa/bbb/')

			expect(storage.get_object_info('/aaa/bbb')).not_to be nil
			expect(storage.get_object_info('/aaa/ccc/xxx')).not_to be nil

		end

		it 'removes all objects when specified the root as the prefix' do

			path = storage.create_untracked_file

			storage.register_object(path, '/aaa')
			storage.register_object(path, '/aaa/bbb/ccc')

			storage.deregister_objects('/')

			expect(storage.get_object_info('/aaa')).to be nil
			expect(storage.get_object_info('/aaa/bbb/ccc')).to be nil

		end

		it 'removes all objects when specified an empty prefix' do

			path = storage.create_untracked_file

			storage.register_object(path, '/aaa')
			storage.register_object(path, '/aaa/bbb/ccc')

			storage.deregister_objects('')

			expect(storage.get_object_info('/aaa')).to be nil
			expect(storage.get_object_info('/aaa/bbb/ccc')).to be nil

		end

		it 'does not raise an error when there is no object to remove' do

			expect{storage.deregister_objects('/aaa')}.not_to raise_error

		end

	end

	describe '#sweep_untracked_files' do

		it 'removes untracked files' do

			path = storage.create_untracked_file
			storage.sweep_untracked_files

			expect(File.file?(path)).to be false

		end

		it 'does not remove tracked files' do

			path = storage.create_untracked_file
			storage.register_object(path, '/remote-name')
			storage.sweep_untracked_files

			expect(File.file?(path)).to be true

		end

		it 'removes untracked files which is once registered to the database' do

			path = storage.create_untracked_file
			storage.register_object(path, '/remote-name')
			storage.deregister_single_object('/remote-name')
			storage.sweep_untracked_files

			expect(File.file?(path)).to be false

		end

		it 'does not remove a deregistered file which is still registered with another remote path' do

			path = storage.create_untracked_file
			storage.register_object(path, '/aaa')
			storage.register_object(path, '/bbb')
			storage.deregister_single_object('/aaa')
			storage.sweep_untracked_files

			expect(File.file?(path)).to be true

		end

		it 'does not remove unrelated files' do

			path = storage.create_untracked_file
			storage.sweep_untracked_files

			expect(Dir.exist?(dir)).to be true
			expect(File.file?(File.join(dir, Ayari::LocalStorage::SQLITE_DATABASE_FILENAME))).to be true

		end

	end

	describe '#escape_for_sql_like_query' do

		it 'escapes the given text correctly' do

			text = '\\\\abc\\\\def%ghi\\%jkl%\\mno\\'
			escaped = Ayari::LocalStorage.escape_for_sql_like_query(text)
			expect(escaped).to eq '\\\\\\\\abc\\\\\\\\def\\%ghi\\\\\\%jkl\\%\\\\mno\\\\'

		end

	end

end
