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

end
