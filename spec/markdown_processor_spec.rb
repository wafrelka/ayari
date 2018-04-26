require 'hashie'
require 'rspec_helper'
require 'ayari/markdown/processor'


describe Ayari::Markdown::Processor do

	let(:processor) { Ayari::Markdown::Processor }
	let(:error) { Ayari::Markdown::InvalidContent }

	describe '#parse_markdown_parameters' do

		let(:template_path) { '/path/to/template' }
		let(:sym_md_opts) { { key_a: 'value_a', key_b: { key_c: 'value_c' } } }
		let(:sym_other_params) { { key_x: 'value_x', key_y: { key_z: 123 } } }
		let(:sym_full_params) { { template: template_path, opts: sym_md_opts }.merge(sym_other_params) }

		let(:template_arg) { { 'template' => template_path } }
		let(:md_opts_arg) { { 'opts' => Hashie::stringify_keys(sym_md_opts) } }
		let(:other_params_arg) { Hashie::stringify_keys(sym_other_params) }

		it 'parses `template` option' do

			res = processor.parse_markdown_parameters(template_arg)

			expect(res[0]).to eq template_path

		end

		it 'parses `opts` option' do

			res = processor.parse_markdown_parameters(
				template_arg.merge(md_opts_arg)
			)

			expect(res[1]).to eq sym_md_opts

		end

		it 'parses other parameters' do

			res = processor.parse_markdown_parameters(
				template_arg.merge(md_opts_arg).merge(other_params_arg)
			)

			expect(res[2]).to eq sym_full_params

		end

		it 'raises an exception when `template_path` is missing' do

			expect{ processor.parse_markdown_parameters(md_opts_arg) }.to raise_error(error)

		end

		it 'raises an exception when parameters are not a `Hash` object' do

			params = 'invalid'
			expect{ processor.parse_markdown_parameters(params) }.to raise_error(error)

		end

		it 'raises an exception when `opts` are not a `Hash` object' do

			params = template_arg.merge(md_opts_arg).merge({'opts' => 'invalid'})
			expect{ processor.parse_markdown_parameters(params) }.to raise_error(error)

		end

	end

	describe '#parse_markdown_text' do

		let(:template_path) { '/path/to/template' }
		let(:md_opts) { { key_a: 'value_a', key_b: { key_c: 'value_c' } } }
		let(:other_params) { { key_x: 'value_x', key_y: { key_z: 123 } } }
		let(:full_params) { other_params.merge({ template: template_path, opts: md_opts }) }

		let(:params_body) { "template: /path/to/template\n"\
			"opts: { key_a: value_a, key_b: { key_c: value_c } }\n"\
			"key_x: value_x\n"\
			"key_y: \n"\
			"  key_z: 123" }
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

		it 'parses hr elements correctly' do

			new_body = [body, params_mark, body, params_mark].join("\n")
			txt = [params_mark, params_body, params_mark, new_body].join("\n")
			res = processor.parse_markdown_text(txt)

			expect(res).to eq [new_body, template_path, md_opts, full_params]

		end

	end

	describe '#process_text' do

		# TODO: Write the tests

	end

end
