require 'rspec_helper'
require 'ayari/processor/markdown_processor'


describe Ayari::Processor::MarkdownProcessor do

	let(:processor) { Ayari::Processor::MarkdownProcessor }
	let(:error) { Ayari::Processor::InvalidContent }

	describe '#parse_markdown_parameters' do

		let(:template_path) { '/path/to/template' }
		let(:md_opts) { { key_a: 'value_a', key_b: { key_c: 'value_c' } } }
		let(:other_params) { { key_x: 'value_x', key_y: { key_z: 123 } } }
		let(:template_key) { 'template' }
		let(:opts_key) { 'opts' }

		it 'parses `template` option' do

			res = processor.parse_markdown_parameters({
				template_key => template_path
			})

			expect(res[0]).to eq template_path

		end

		it 'parses `opts` option' do

			res = processor.parse_markdown_parameters({
				template_key => template_path,
				opts_key => md_opts
			})

			expect(res[1]).to eq md_opts

		end

		it 'parses other parameters' do

			params = {
				template_key => template_path,
				opts_key => md_opts
			}.merge(other_params)

			res = processor.parse_markdown_parameters(params)

			expect(res[2]).to eq params

		end

		it 'raises an exception when `template_path` is missing' do

			params = { opts_key => md_opts }
			expect{ processor.parse_markdown_parameters(params) }.to raise_error(error)

		end

		it 'raises an exception when parameters are not a `Hash` object' do

			params = 'invalid'
			expect{ processor.parse_markdown_parameters(params) }.to raise_error(error)

		end

		it 'raises an exception when `opts` are not a `Hash` object' do

			params = { template_key => template_path, opts_key => 'invalid' }
			expect{ processor.parse_markdown_parameters(params) }.to raise_error(error)

		end

	end

	describe '#parse_markdown_text' do

		let(:template_path) { '/path/to/template' }
		let(:md_opts) { { 'key_a' => 'value_a' } }
		let(:other_params) { { 'key_x' => 'value_x' } }
		let(:full_params) { other_params.merge({ 'template' => template_path, 'opts' => md_opts }) }
		let(:params_body) { "template: /path/to/template\nopts: { key_a: value_a }\nkey_x: value_x" }
		let(:params_mark) { '---' }
		let(:body) { "body\n" * 100 }

		it 'parses YAML-formatted parameters' do

			txt = [params_mark, params_body, params_mark, body].join("\n")
			res = processor.parse_markdown_text(txt)

			expect(res[1..3]).to eq [template_path, md_opts, full_params]

		end

		it 'parses body' do

			txt = [params_mark, params_body, params_mark, body].join("\n")
			res = processor.parse_markdown_text(txt)

			expect(res[0]).to eq body

		end

		it 'parses correctly when the body is empty' do

			txt = [params_mark, params_body, params_mark].join("\n")
			res = processor.parse_markdown_text(txt)

			expect(res).to eq ['', template_path, md_opts, full_params]

		end

		it 'raises an exception when the first mark is not found' do

			txt = [params_body, params_mark].join("\n")
			expect{ processor.parse_markdown_text(txt) }.to raise_error(error)

		end

		it 'raises an exception when the second mark is not found' do

			txt = [params_mark, params_body].join("\n")
			expect{ processor.parse_markdown_text(txt) }.to raise_error(error)

		end

		it 'raises an exception when the text is empty' do

			txt = ''
			expect{ processor.parse_markdown_text(txt) }.to raise_error(error)

		end

	end

	describe '#process_text' do

		# TODO: Write the tests

	end

end
