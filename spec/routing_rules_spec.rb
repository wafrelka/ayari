require 'rspec_helper'
require 'ayari/routing_rules'


describe Ayari::RoutingRules do

	let(:rules) { Ayari::RoutingRules }

	describe '#get_candidates' do

		context 'original_path is suffixed with a slash' do

			it 'returns correct candidates in correct order' do

				path = '/abc/def/'
				expected = [
					'/abc/def/index.md',
					'/abc/def/index.haml',
					'/abc/def/index.html',
				]

				expect(rules.get_candidates(path)).to eq expected

			end

			it 'returns correct candidates in correct order' do

				path = '/'
				expected = [
					'/index.md',
					'/index.haml',
					'/index.html',
				]

				expect(rules.get_candidates(path)).to eq expected

			end

		end

		context 'original_path is not suffixed with a slash' do

			it 'returns correct candidates in correct order' do

				path = '/abc/def'
				expected = [
					'/abc/def',
					'/abc/def.md',
					'/abc/def.haml',
					'/abc/def.html',
					'/abc/def.txt',
					'/abc/def/index.md',
					'/abc/def/index.haml',
					'/abc/def/index.html',
				]

				expect(rules.get_candidates(path)).to eq expected

			end

			it 'returns correct candidates in correct order' do

				path = '/abc/def.txt'
				expected = [
					'/abc/def.txt',
					'/abc/def.txt.md',
					'/abc/def.txt.haml',
					'/abc/def.txt.html',
					'/abc/def.txt.txt',
					'/abc/def.txt/index.md',
					'/abc/def.txt/index.haml',
					'/abc/def.txt/index.html',
				]

				expect(rules.get_candidates(path)).to eq expected

			end

		end

	end

	describe '#get_candidates' do

		context '`from` is a correct absolute path' do

			context '`path` is a correct relative file path' do

				it 'should return the correct path' do
					path = 'ghi/jkl.txt'
					from = '/abc/def.txt'
					expected = '/abc/ghi/jkl.txt'
					expect(rules.get_remote_path(path, from)).to eq expected
				end

				it 'should return the correct path when `from` is a direct child of the root' do
					path = 'ghi/jkl.txt'
					from = '/def.txt'
					expected = '/ghi/jkl.txt'
					expect(rules.get_remote_path(path, from)).to eq expected
				end

				it 'should handle \'..\' correctly' do
					path = '../jkl.txt'
					from = '/abc/def.txt'
					expected = '/jkl.txt'
					expect(rules.get_remote_path(path, from)).to eq expected
				end

				it 'should ignore useless \'..\'' do
					path = '../../jkl.txt'
					from = '/abc/def.txt'
					expected = '/jkl.txt'
					expect(rules.get_remote_path(path, from)).to eq expected
				end

			end

			context '`path` is a correct absolute file path' do

				it 'should return the correct path' do
					path = '/ghi/jkl.txt'
					from = '/abc/def.txt'
					expected = '/ghi/jkl.txt'
					expect(rules.get_remote_path(path, from)).to eq expected
				end

			end

			context '`path` is a correct relative directory path' do

				it 'should return the correct path' do
					path = 'ghi/jkl/'
					from = '/abc/def.txt'
					expected = '/abc/ghi/jkl'
					expect(rules.get_remote_path(path, from)).to eq expected
				end

			end

		end

		context '`from` is invalid' do

			it 'should raise an error when `from` does not start with \'/\'' do
				path = 'ghi/jkl.txt'
				from = 'abc/def.txt'
				expect{rules.get_remote_path(path, from)}.to raise_error(StandardError)
			end

			it 'should raise an error when `from` ends with \'/\'' do
				path = 'ghi/jkl.txt'
				from = '/abc/'
				expect{rules.get_remote_path(path, from)}.to raise_error(StandardError)
			end

		end

	end

end
